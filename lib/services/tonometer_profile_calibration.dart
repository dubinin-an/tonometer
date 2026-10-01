import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/tonometer_profile.dart';
import 'automatic_lcd_locator.dart';
import 'cv_config.dart';

class TonometerCalibrationDraft {
  const TonometerCalibrationDraft({
    required this.sourcePhoto,
    required this.rectifiedLcd,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.lcdCorners,
    required this.canonicalWidth,
    required this.canonicalHeight,
    required this.suggestedRegions,
  });

  final Uint8List sourcePhoto;
  final Uint8List rectifiedLcd;
  final int sourceWidth;
  final int sourceHeight;
  final List<(double, double)> lcdCorners;
  final int canonicalWidth;
  final int canonicalHeight;
  final List<NormalizedRegion> suggestedRegions;
}

Future<TonometerCalibrationDraft> prepareTonometerCalibration(
  Uint8List photoBytes, {
  CvConfig config = const CvConfig(),
}) async {
  final located = await Isolate.run(
    () => locateCalibrationLcd(photoBytes, config),
  );
  final regions = await Isolate.run(
    () => _suggestRegions(located.rectifiedBytes),
  );
  return TonometerCalibrationDraft(
    sourcePhoto: photoBytes,
    rectifiedLcd: located.rectifiedBytes,
    sourceWidth: located.imageWidth,
    sourceHeight: located.imageHeight,
    lcdCorners: located.corners,
    canonicalWidth: located.canonicalWidth,
    canonicalHeight: located.canonicalHeight,
    suggestedRegions: regions,
  );
}

Future<TonometerCalibrationDraft> prepareTonometerCalibrationFromCorners(
  Uint8List photoBytes,
  List<(double, double)> corners,
) async {
  final located = await Isolate.run(
    () => rectifyCalibrationLcd(photoBytes, corners),
  );
  final regions = await Isolate.run(
    () => _suggestRegions(located.rectifiedBytes),
  );
  return TonometerCalibrationDraft(
    sourcePhoto: photoBytes,
    rectifiedLcd: located.rectifiedBytes,
    sourceWidth: located.imageWidth,
    sourceHeight: located.imageHeight,
    lcdCorners: located.corners,
    canonicalWidth: located.canonicalWidth,
    canonicalHeight: located.canonicalHeight,
    suggestedRegions: regions,
  );
}

List<NormalizedRegion> _suggestRegions(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return _fallbackRegions;
  final image = img.bakeOrientation(decoded);
  var luminanceSum = 0.0;
  for (final pixel in image) {
    luminanceSum += pixel.luminance;
  }
  final mean = luminanceSum / (image.width * image.height);
  final threshold = (mean - 22).clamp(45, 205);
  final density = List<double>.filled(image.height, 0);
  for (var y = 0; y < image.height; y++) {
    var dark = 0;
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).luminance < threshold) dark++;
    }
    density[y] = dark / image.width;
  }
  final active = List<bool>.filled(image.height, false);
  final radius = (image.height * 0.012).round().clamp(3, 18);
  for (var y = 0; y < image.height; y++) {
    var total = 0.0;
    var count = 0;
    for (var sample = y - radius; sample <= y + radius; sample++) {
      if (sample < 0 || sample >= image.height) continue;
      total += density[sample];
      count++;
    }
    active[y] = total / count > 0.045;
  }
  final runs = <(int, int)>[];
  int? start;
  for (var y = 0; y <= image.height; y++) {
    final enabled = y < image.height && active[y];
    if (enabled && start == null) start = y;
    if (!enabled && start != null) {
      if (y - start > image.height * 0.075) runs.add((start, y));
      start = null;
    }
  }
  if (runs.length < 3) return _fallbackRegions;
  final selected = [...runs]
    ..sort((a, b) => (b.$2 - b.$1).compareTo(a.$2 - a.$1));
  final rows = selected.take(3).toList()..sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (final row in rows) _regionForRow(image, threshold, row.$1, row.$2),
  ];
}

NormalizedRegion _regionForRow(
  img.Image image,
  num threshold,
  int top,
  int bottom,
) {
  var left = image.width;
  var right = 0;
  for (var y = top; y < bottom; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).luminance >= threshold) continue;
      if (x < left) left = x;
      if (x > right) right = x;
    }
  }
  if (right <= left) {
    left = (image.width * 0.08).round();
    right = (image.width * 0.94).round();
  }
  final horizontalPadding = image.width * 0.035;
  final verticalPadding = image.height * 0.018;
  final x = ((left - horizontalPadding) / image.width).clamp(0.0, 0.92);
  final y = ((top - verticalPadding) / image.height).clamp(0.0, 0.92);
  final width = ((right - left + horizontalPadding * 2) / image.width).clamp(
    0.12,
    1 - x,
  );
  final height = ((bottom - top + verticalPadding * 2) / image.height).clamp(
    0.10,
    1 - y,
  );
  return NormalizedRegion(x: x, y: y, width: width, height: height);
}

const _fallbackRegions = <NormalizedRegion>[
  NormalizedRegion(x: 0.08, y: 0.10, width: 0.84, height: 0.25),
  NormalizedRegion(x: 0.08, y: 0.39, width: 0.84, height: 0.25),
  NormalizedRegion(x: 0.24, y: 0.70, width: 0.68, height: 0.22),
];

Map<String, dynamic> buildTonometerProfile({
  required String id,
  required String name,
  required String? manufacturer,
  required String? model,
  required TonometerCalibrationDraft calibration,
  required List<NormalizedRegion> regions,
  required int systolic,
  required int diastolic,
  required int pulse,
}) {
  Map<String, dynamic> field(
    String id,
    String label,
    String unit,
    NormalizedRegion region,
    int minimum,
    int maximum,
  ) {
    final slotWidth = region.width / 3;
    return {
      'id': id,
      'label': label,
      'unit': unit,
      'rect': region.toJson(),
      'digitCount': 3,
      'alignment': 'right',
      'allowLeadingBlank': true,
      'digitSlots': [
        for (var index = 0; index < 3; index++)
          {
            'x': region.x + slotWidth * index,
            'y': region.y,
            'width': slotWidth,
            'height': region.height,
          },
      ],
      'validation': {'min': minimum, 'max': maximum},
    };
  }

  Map<String, double> point((double, double) value) => {
    'x': value.$1,
    'y': value.$2,
  };

  final xs = calibration.lcdCorners.map((point) => point.$1);
  final ys = calibration.lcdCorners.map((point) => point.$2);
  final lcdLeft = xs.reduce(math.min);
  final lcdRight = xs.reduce(math.max);
  final lcdTop = ys.reduce(math.min);
  final lcdBottom = ys.reduce(math.max);
  final maskPaddingX = (lcdRight - lcdLeft) * 0.12;
  final maskPaddingY = (lcdBottom - lcdTop) * 0.12;
  final maskLeft = (lcdLeft - maskPaddingX).clamp(
    0,
    calibration.sourceWidth - 1,
  );
  final maskTop = (lcdTop - maskPaddingY).clamp(
    0,
    calibration.sourceHeight - 1,
  );
  final maskRight = (lcdRight + maskPaddingX).clamp(
    maskLeft + 1,
    calibration.sourceWidth,
  );
  final maskBottom = (lcdBottom + maskPaddingY).clamp(
    maskTop + 1,
    calibration.sourceHeight,
  );

  return {
    'schemaVersion': 1,
    'status': 'testing',
    'id': id,
    'name': name,
    'device': {
      'manufacturer': manufacturer?.trim().isEmpty == true
          ? null
          : manufacturer?.trim(),
      'model': model?.trim().isEmpty == true ? null : model?.trim(),
    },
    'capture': {
      'orientation': 'portrait',
      'screenGuideAspectRatio':
          calibration.canonicalWidth / calibration.canonicalHeight,
      'instruction': 'Keep the complete device visible and avoid glare',
    },
    'normalization': {
      'coordinateSpace': 'rectified_inner_lcd',
      'canonicalWidth': calibration.canonicalWidth,
      'canonicalHeight': calibration.canonicalHeight,
      'polarity': 'dark_segments_on_light_background',
      'preprocessing': {
        'colorMode': 'grayscale',
        'illuminationNormalization': 'adaptive',
        'thresholdMode': 'adaptive',
        'denoise': 'light',
      },
    },
    'recognizer': {
      'type': 'seven_segment',
      'layout': 'standard_7_segment',
      'segmentOrder': ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      'digitMap': {
        '0': ['a', 'b', 'c', 'd', 'e', 'f'],
        '1': ['b', 'c'],
        '2': ['a', 'b', 'd', 'e', 'g'],
        '3': ['a', 'b', 'c', 'd', 'g'],
        '4': ['b', 'c', 'f', 'g'],
        '5': ['a', 'c', 'd', 'f', 'g'],
        '6': ['a', 'c', 'd', 'e', 'f', 'g'],
        '7': ['a', 'b', 'c'],
        '8': ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        '9': ['a', 'b', 'c', 'd', 'f', 'g'],
      },
    },
    'fields': [
      field('systolic', 'SYS', 'mmHg', regions[0], 40, 300),
      field('diastolic', 'DIA', 'mmHg', regions[1], 20, 200),
      field('pulse', 'Pulse', 'bpm', regions[2], 25, 250),
    ],
    'calibrationReference': {
      'fileName': '$id.reference.jpg',
      'imageSize': {
        'width': calibration.sourceWidth,
        'height': calibration.sourceHeight,
      },
      'featureMaskRect': {
        'x': maskLeft.round(),
        'y': maskTop.round(),
        'width': (maskRight - maskLeft).round(),
        'height': (maskBottom - maskTop).round(),
      },
      'innerLcdQuadrilateral': {
        'topLeft': point(calibration.lcdCorners[0]),
        'topRight': point(calibration.lcdCorners[1]),
        'bottomRight': point(calibration.lcdCorners[2]),
        'bottomLeft': point(calibration.lcdCorners[3]),
      },
      'expectedValues': {
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
      },
    },
    'testing': {'recommendedPhotoCount': 3, 'completedPhotoCount': 0},
    'limitations': [
      'Automatically generated profile. Verify it with several photographs.',
    ],
  };
}
