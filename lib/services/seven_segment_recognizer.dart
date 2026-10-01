import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../data/tonometer_profile_repository.dart';
import '../domain/tonometer_profile.dart';
import 'automatic_lcd_locator.dart';
import 'cv_config.dart';

class RecognitionResult {
  const RecognitionResult({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.complete,
    this.rawDigits = const {},
  });

  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final bool complete;
  final Map<String, String> rawDigits;
}

class RecognitionLayout {
  const RecognitionLayout({
    required this.width,
    required this.height,
    required this.regions,
  });

  final int width;
  final int height;
  final Map<String, List<Rect>> regions;
}

class SevenSegmentRecognizer {
  const SevenSegmentRecognizer({
    this.config = const CvConfig(),
    this.profileRepository,
  });

  final CvConfig config;
  final TonometerProfileRepository? profileRepository;

  Future<RecognitionLayout> loadLayout() async {
    final json =
        jsonDecode((await _loadProfile()).json) as Map<String, dynamic>;
    final normalization = json['normalization'] as Map<String, dynamic>;
    final regions = <String, List<Rect>>{};
    for (final rawField in json['fields'] as List<dynamic>) {
      final field = rawField as Map<String, dynamic>;
      regions[field['id'] as String] = [
        for (final rawSlot in field['digitSlots'] as List<dynamic>)
          _rectFromJson(rawSlot as Map<String, dynamic>),
      ];
    }
    return RecognitionLayout(
      width: normalization['canonicalWidth'] as int,
      height: normalization['canonicalHeight'] as int,
      regions: regions,
    );
  }

  Future<TonometerProfileBundle> _loadProfile() async {
    final repository = profileRepository;
    if (repository != null) return repository.loadActive();
    final profileJson = await rootBundle.loadString(config.profileAsset);
    final deviceProfile = LcdDeviceProfile.fromJsonString(profileJson);
    final reference = await rootBundle.load(deviceProfile.referenceAsset!);
    return TonometerProfileBundle(
      json: profileJson,
      referenceBytes: reference.buffer.asUint8List(
        reference.offsetInBytes,
        reference.lengthInBytes,
      ),
    );
  }

  Future<RecognitionResult> recognize(Uint8List jpegBytes) async {
    final rectified = await preparePhoto(jpegBytes);
    return recognizeRectified(rectified);
  }

  Future<Uint8List> preparePhoto(Uint8List jpegBytes) async {
    final profile = await _loadProfile();
    final deviceProfile = LcdDeviceProfile.fromJsonString(profile.json);
    return Isolate.run(
      () => locateAndRectifyLcd(
        jpegBytes,
        profile.referenceBytes,
        deviceProfile,
        config,
      ),
    );
  }

  Future<RecognitionResult> recognizeRectified(Uint8List rectifiedBytes) async {
    final profileJson = (await _loadProfile()).json;
    return Isolate.run(
      () => _recognize(
        rectifiedBytes,
        profileJson,
        config,
        alreadyRectified: true,
      ),
    );
  }

  Future<Uint8List> buildBlackWhitePreview(Uint8List rectifiedBytes) async {
    return Isolate.run(() => _buildBlackWhitePreview(rectifiedBytes, config));
  }

  Future<RecognitionResult> recognizeCalibrationReference(
    Uint8List jpegBytes,
  ) async {
    final profileJson = (await _loadProfile()).json;
    return Isolate.run(
      () => _recognize(
        jpegBytes,
        profileJson,
        config,
        useCalibrationReference: true,
      ),
    );
  }
}

Rect _rectFromJson(Map<String, dynamic> json) => Rect.fromLTWH(
  (json['x'] as num).toDouble(),
  (json['y'] as num).toDouble(),
  (json['width'] as num).toDouble(),
  (json['height'] as num).toDouble(),
);

Uint8List _buildBlackWhitePreview(Uint8List jpegBytes, CvConfig config) {
  final decoded = img.decodeImage(jpegBytes);
  if (decoded == null) {
    throw const FormatException('Не удалось прочитать фотографию');
  }
  final source = img.bakeOrientation(decoded);
  final width = source.width;
  final height = source.height;
  final gray = _rectifiedGrayscale(source, width, height, [
    const _Point(0, 0),
    _Point(source.width - 1, 0),
    _Point(source.width - 1, source.height - 1),
    _Point(0, source.height - 1),
  ]);
  final enhanced = _stretchContrast(gray, config);
  final mask = _cleanBinaryMask(
    _adaptiveMask(
      enhanced,
      width,
      height,
      config.previewAdaptiveOffset,
      config.adaptiveRadius,
    ),
    width,
    height,
    config.binaryMajorityThreshold,
  );
  final preview = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final value = mask[y * width + x] == 1 ? 0 : 255;
      preview.setPixelRgb(x, y, value, value, value);
    }
  }
  return Uint8List.fromList(img.encodePng(preview));
}

RecognitionResult _recognize(
  Uint8List jpegBytes,
  String profileJson,
  CvConfig config, {
  bool useCalibrationReference = false,
  bool alreadyRectified = false,
}) {
  final decoded = img.decodeJpg(jpegBytes);
  if (decoded == null) {
    throw const FormatException('Не удалось прочитать фотографию');
  }
  final source = img.bakeOrientation(decoded);
  final profile = jsonDecode(profileJson) as Map<String, dynamic>;
  final normalization = profile['normalization'] as Map<String, dynamic>;
  final width = normalization['canonicalWidth'] as int;
  final height = normalization['canonicalHeight'] as int;
  final sourcePoints = alreadyRectified
      ? [
          const _Point(0, 0),
          _Point(source.width - 1, 0),
          _Point(source.width - 1, source.height - 1),
          _Point(0, source.height - 1),
        ]
      : useCalibrationReference
      ? _calibrationPoints(profile)
      : throw StateError('Для снимка требуется автоматический поиск LCD');
  final grayscale = _rectifiedGrayscale(source, width, height, sourcePoints);
  final highContrast = _stretchContrast(grayscale, config);
  final recognizerProfile = profile['recognizer'] as Map<String, dynamic>;
  final digitSegments = <String, Set<String>>{
    for (final entry
        in (recognizerProfile['digitMap'] as Map<String, dynamic>).entries)
      entry.key: {
        for (final segment in entry.value as List<dynamic>) segment as String,
      },
  };
  final values = <String, int?>{};
  final rawDigits = <String, String>{};
  var complete = true;
  for (final rawField in profile['fields'] as List<dynamic>) {
    final field = rawField as Map<String, dynamic>;
    final fieldRect = _Rect.fromJson(field['rect'] as Map<String, dynamic>);
    final masks = <Uint8List>[];
    for (final gray in [highContrast, grayscale]) {
      for (final adjustment in config.fieldThresholdAdjustments) {
        final mask = _fieldOtsuMask(
          gray,
          width,
          height,
          fieldRect,
          adjustment,
          config.fieldExpansionPixels,
        );
        masks.add(
          _cleanBinaryMask(mask, width, height, config.binaryMajorityThreshold),
        );
        masks.add(mask);
      }
      for (final offset in config.fieldAdaptiveOffsets) {
        final mask = _adaptiveMask(
          gray,
          width,
          height,
          offset,
          config.adaptiveRadius,
        );
        masks.add(
          _cleanBinaryMask(mask, width, height, config.binaryMajorityThreshold),
        );
        masks.add(mask);
      }
    }
    var bestAttempt = '';
    var bestScore = 1 << 20;
    final slots = [
      for (final rawSlot in field['digitSlots'] as List<dynamic>)
        _Rect.fromJson(rawSlot as Map<String, dynamic>),
    ];
    for (final mask in masks) {
      final components = _components(mask, width, height);
      final attempt = slots
          .map(
            (slot) => _recognizeSlot(
              components,
              slot,
              width,
              height,
              config,
              digitSegments,
            ),
          )
          .join();
      final score = _unknownCount(attempt);
      if (score < bestScore ||
          (score == bestScore &&
              _validFieldAttempt(attempt, field) &&
              !_validFieldAttempt(bestAttempt, field))) {
        bestAttempt = attempt;
        bestScore = score;
      }
    }
    final text = bestAttempt;
    if (!_validFieldAttempt(text, field)) complete = false;
    rawDigits[field['id'] as String] = text;
    values[field['id'] as String] = text.isEmpty || text.contains('?')
        ? null
        : int.tryParse(text);
  }
  return RecognitionResult(
    systolic: values['systolic'],
    diastolic: values['diastolic'],
    pulse: values['pulse'],
    complete: complete && values.values.every((value) => value != null),
    rawDigits: rawDigits,
  );
}

bool _validFieldAttempt(String attempt, Map<String, dynamic> field) {
  final value = int.tryParse(attempt);
  final validation = field['validation'] as Map<String, dynamic>;
  return !attempt.contains('?') &&
      value != null &&
      value >= (validation['min'] as num) &&
      value <= (validation['max'] as num);
}

List<_Point> _calibrationPoints(Map<String, dynamic> profile) {
  final reference = profile['calibrationReference'] as Map<String, dynamic>;
  final quadrilateral =
      reference['innerLcdQuadrilateral'] as Map<String, dynamic>;
  _Point point(String name) {
    final value = quadrilateral[name] as Map<String, dynamic>;
    return _Point(
      (value['x'] as num).toDouble(),
      (value['y'] as num).toDouble(),
    );
  }

  return [
    point('topLeft'),
    point('topRight'),
    point('bottomRight'),
    point('bottomLeft'),
  ];
}

List<int> _rectifiedGrayscale(
  img.Image source,
  int width,
  int height,
  List<_Point> sourcePoints,
) {
  final coefficients = _perspectiveCoefficients([
    _Point(0, 0),
    _Point(width - 1, 0),
    _Point(width - 1, height - 1),
    _Point(0, height - 1),
  ], sourcePoints);
  final result = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final denominator = coefficients[6] * x + coefficients[7] * y + 1;
      final sourceX =
          ((coefficients[0] * x + coefficients[1] * y + coefficients[2]) /
                  denominator)
              .round()
              .clamp(0, source.width - 1);
      final sourceY =
          ((coefficients[3] * x + coefficients[4] * y + coefficients[5]) /
                  denominator)
              .round()
              .clamp(0, source.height - 1);
      final pixel = source.getPixel(sourceX, sourceY);
      result[y * width + x] =
          (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
    }
  }
  return result;
}

List<double> _perspectiveCoefficients(List<_Point> output, List<_Point> input) {
  final matrix = List.generate(8, (_) => List.filled(9, 0.0));
  for (var index = 0; index < 4; index++) {
    final x = output[index].x;
    final y = output[index].y;
    final u = input[index].x;
    final v = input[index].y;
    matrix[index * 2] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
    matrix[index * 2 + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
  }
  for (var column = 0; column < 8; column++) {
    var pivot = column;
    for (var row = column + 1; row < 8; row++) {
      if (matrix[row][column].abs() > matrix[pivot][column].abs()) pivot = row;
    }
    final swap = matrix[column];
    matrix[column] = matrix[pivot];
    matrix[pivot] = swap;
    final divisor = matrix[column][column];
    if (divisor.abs() < 1e-12) throw StateError('Некорректная геометрия LCD');
    for (var item = column; item <= 8; item++) {
      matrix[column][item] /= divisor;
    }
    for (var row = 0; row < 8; row++) {
      if (row == column) continue;
      final factor = matrix[row][column];
      for (var item = column; item <= 8; item++) {
        matrix[row][item] -= factor * matrix[column][item];
      }
    }
  }
  return [for (var row = 0; row < 8; row++) matrix[row][8]];
}

int _unknownCount(String value) {
  if (value.isEmpty) return 1 << 20;
  return '?'.allMatches(value).length;
}

List<int> _stretchContrast(List<int> gray, CvConfig config) {
  final histogram = List<int>.filled(256, 0);
  for (final value in gray) {
    histogram[value]++;
  }
  final lowTarget = (gray.length * config.contrastLowPercentile).round();
  final highTarget = (gray.length * config.contrastHighPercentile).round();
  var accumulated = 0;
  var low = 0;
  var high = 255;
  for (var value = 0; value < 256; value++) {
    accumulated += histogram[value];
    if (accumulated >= lowTarget) {
      low = value;
      break;
    }
  }
  accumulated = 0;
  for (var value = 0; value < 256; value++) {
    accumulated += histogram[value];
    if (accumulated >= highTarget) {
      high = value;
      break;
    }
  }
  if (high <= low + config.minimumContrastRange) return List<int>.from(gray);
  return [
    for (final value in gray)
      (((value - low) * 255) / (high - low)).round().clamp(0, 255),
  ];
}

Uint8List _cleanBinaryMask(
  Uint8List source,
  int width,
  int height,
  int majorityThreshold,
) {
  final result = Uint8List(source.length);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      var darkPixels = 0;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          darkPixels += source[(y + dy) * width + x + dx];
        }
      }
      // A small majority filter removes isolated LCD texture and fills tiny
      // bright holes inside a dark seven-segment bar.
      result[y * width + x] = darkPixels >= majorityThreshold ? 1 : 0;
    }
  }
  return result;
}

Uint8List _fieldOtsuMask(
  List<int> gray,
  int width,
  int height,
  _Rect field,
  int adjustment,
  int expansionPixels,
) {
  final box = field
      .pixels(width, height)
      .expanded(expansionPixels, width, height);
  final histogram = List<int>.filled(256, 0);
  var count = 0;
  var sum = 0.0;
  for (var y = box.top; y < box.bottom; y++) {
    for (var x = box.left; x < box.right; x++) {
      final value = gray[y * width + x];
      histogram[value]++;
      count++;
      sum += value;
    }
  }
  var darkWeight = 0;
  var darkSum = 0.0;
  var bestVariance = -1.0;
  var threshold = 128;
  for (var candidate = 0; candidate < 256; candidate++) {
    darkWeight += histogram[candidate];
    if (darkWeight == 0) continue;
    final lightWeight = count - darkWeight;
    if (lightWeight == 0) break;
    darkSum += candidate * histogram[candidate];
    final darkMean = darkSum / darkWeight;
    final lightMean = (sum - darkSum) / lightWeight;
    final difference = darkMean - lightMean;
    final variance = darkWeight * lightWeight * difference * difference;
    if (variance > bestVariance) {
      bestVariance = variance;
      threshold = candidate;
    }
  }
  final effectiveThreshold = (threshold + adjustment).clamp(0, 255);
  final mask = Uint8List(width * height);
  for (var y = box.top; y < box.bottom; y++) {
    for (var x = box.left; x < box.right; x++) {
      if (gray[y * width + x] <= effectiveThreshold) {
        mask[y * width + x] = 1;
      }
    }
  }
  return mask;
}

Uint8List _adaptiveMask(
  List<int> gray,
  int width,
  int height,
  int offset,
  int radius,
) {
  final integral = List<int>.filled((width + 1) * (height + 1), 0);
  for (var y = 0; y < height; y++) {
    var rowSum = 0;
    for (var x = 0; x < width; x++) {
      rowSum += gray[y * width + x];
      integral[(y + 1) * (width + 1) + x + 1] =
          integral[y * (width + 1) + x + 1] + rowSum;
    }
  }
  final mask = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    final top = (y - radius).clamp(0, height - 1);
    final bottom = (y + radius + 1).clamp(1, height);
    for (var x = 0; x < width; x++) {
      final left = (x - radius).clamp(0, width - 1);
      final right = (x + radius + 1).clamp(1, width);
      final sum =
          integral[bottom * (width + 1) + right] -
          integral[top * (width + 1) + right] -
          integral[bottom * (width + 1) + left] +
          integral[top * (width + 1) + left];
      final mean = sum / ((right - left) * (bottom - top));
      mask[y * width + x] = gray[y * width + x] < mean - offset ? 1 : 0;
    }
  }
  return mask;
}

List<_Component> _components(Uint8List mask, int width, int height) {
  final visited = Uint8List(mask.length);
  final result = <_Component>[];
  for (var start = 0; start < mask.length; start++) {
    if (mask[start] == 0 || visited[start] == 1) continue;
    final stack = <int>[start];
    visited[start] = 1;
    var area = 0;
    var left = width;
    var right = 0;
    var top = height;
    var bottom = 0;
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final x = current % width;
      final y = current ~/ width;
      area++;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
      for (final next in [
        current - 1,
        current + 1,
        current - width,
        current + width,
      ]) {
        if (next < 0 ||
            next >= mask.length ||
            visited[next] == 1 ||
            mask[next] == 0) {
          continue;
        }
        final nextX = next % width;
        final nextY = next ~/ width;
        if ((nextX - x).abs() + (nextY - y).abs() != 1) continue;
        visited[next] = 1;
        stack.add(next);
      }
    }
    result.add(_Component(area, left, top, right + 1, bottom + 1));
  }
  return result;
}

String _recognizeSlot(
  List<_Component> components,
  _Rect slot,
  int width,
  int height,
  CvConfig config,
  Map<String, Set<String>> digitSegments,
) {
  final box = slot.pixels(width, height);
  final inside = components.where((component) {
    return component.centerX >= box.left &&
        component.centerX <= box.right &&
        component.centerY >= box.top &&
        component.centerY <= box.bottom &&
        component.area >= box.area * config.minimumComponentAreaFraction &&
        component.area <= box.area * config.maximumComponentAreaFraction &&
        component.orientation(config) != null;
  }).toList();
  final horizontal =
      inside
          .where(
            (component) =>
                component.orientation(config) == _Orientation.horizontal,
          )
          .toList()
        ..sort((a, b) => a.centerY.compareTo(b.centerY));
  final vertical = inside
      .where(
        (component) => component.orientation(config) == _Orientation.vertical,
      )
      .toList();
  if (horizontal.isEmpty && vertical.isEmpty) return '';
  if (horizontal.isEmpty &&
      vertical.isNotEmpty &&
      vertical.length <= config.maximumVerticalOnlyComponents) {
    final averageX =
        vertical
            .map((component) => (component.centerX - box.left) / box.width)
            .reduce((sum, value) => sum + value) /
        vertical.length;
    final bounds = config.verticalOnlyDigitHorizontalBounds;
    if (averageX < bounds.$1 || averageX > bounds.$2) return '';
    return '1';
  }

  final segments = <String>{};
  for (final component in horizontal) {
    final y = (component.centerY - box.top) / box.height;
    final centers = config.horizontalSegmentCenters;
    final distances = <String, double>{
      'a': (y - centers.$1).abs(),
      'g': (y - centers.$2).abs(),
      'd': (y - centers.$3).abs(),
    };
    final nearest = distances.entries.reduce(
      (left, right) => left.value <= right.value ? left : right,
    );
    if (nearest.value <= config.horizontalSegmentTolerance) {
      segments.add(nearest.key);
    }
  }
  for (final component in vertical) {
    final x = (component.centerX - box.left) / box.width;
    final y = (component.centerY - box.top) / box.height;
    final left = x < 0.5;
    final top = y < 0.5;
    segments.add(left ? (top ? 'f' : 'e') : (top ? 'b' : 'c'));
  }

  String? bestDigit;
  var bestDistance = 1 << 20;
  var tied = false;
  for (final entry in digitSegments.entries) {
    final distance =
        segments.difference(entry.value).length +
        entry.value.difference(segments).length;
    if (distance < bestDistance) {
      bestDigit = entry.key;
      bestDistance = distance;
      tied = false;
    } else if (distance == bestDistance) {
      tied = true;
    }
  }
  return bestDistance <= config.maximumDigitSegmentDistance && !tied
      ? bestDigit!
      : '?';
}

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}

class _PixelRect {
  const _PixelRect(this.left, this.top, this.right, this.bottom);
  final int left;
  final int top;
  final int right;
  final int bottom;
  int get height => bottom - top;
  int get width => right - left;
  int get area => width * height;
  _PixelRect expanded(int amount, int imageWidth, int imageHeight) =>
      _PixelRect(
        (left - amount).clamp(0, imageWidth),
        (top - amount).clamp(0, imageHeight),
        (right + amount).clamp(0, imageWidth),
        (bottom + amount).clamp(0, imageHeight),
      );
}

class _Rect {
  const _Rect(this.x, this.y, this.width, this.height);
  factory _Rect.fromJson(Map<String, dynamic> json) => _Rect(
    (json['x'] as num).toDouble(),
    (json['y'] as num).toDouble(),
    (json['width'] as num).toDouble(),
    (json['height'] as num).toDouble(),
  );
  final double x;
  final double y;
  final double width;
  final double height;
  _PixelRect pixels(int imageWidth, int imageHeight) => _PixelRect(
    (x * imageWidth).round(),
    (y * imageHeight).round(),
    ((x + width) * imageWidth).round(),
    ((y + height) * imageHeight).round(),
  );
}

enum _Orientation { horizontal, vertical }

class _Component {
  const _Component(this.area, this.left, this.top, this.right, this.bottom);
  final int area;
  final int left;
  final int top;
  final int right;
  final int bottom;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
  _Orientation? orientation(CvConfig config) {
    final ratio = (right - left) / (bottom - top);
    if (ratio >= config.horizontalAspectRatio) return _Orientation.horizontal;
    if (ratio <= config.verticalAspectRatio) return _Orientation.vertical;
    return null;
  }
}
