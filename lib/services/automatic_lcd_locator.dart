import 'dart:math' as math;
import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'cv_config.dart';

class LcdNotFoundException implements Exception {
  const LcdNotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalibrationLcdResult {
  const CalibrationLcdResult({
    required this.rectifiedBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.corners,
    required this.canonicalWidth,
    required this.canonicalHeight,
  });

  final Uint8List rectifiedBytes;
  final int imageWidth;
  final int imageHeight;
  final List<(double, double)> corners;
  final int canonicalWidth;
  final int canonicalHeight;
}

/// Finds the most plausible LCD rectangle without an existing device profile.
/// This is used only while creating a new profile; the saved profile then uses
/// the normal, stricter locator for subsequent measurements.
CalibrationLcdResult locateCalibrationLcd(
  Uint8List photoBytes,
  CvConfig config,
) {
  final source = cv.imdecode(photoBytes, cv.IMREAD_COLOR);
  if (source.isEmpty) {
    source.dispose();
    throw const FormatException('Unable to read the photograph');
  }
  final gray = cv.cvtColor(source, cv.COLOR_BGR2GRAY);
  final equalized = cv.equalizeHist(gray);
  _LcdCandidate? best;
  try {
    for (final variant in [gray, equalized]) {
      final blurred = cv.gaussianBlur(variant, (
        config.locator.blurKernelSize,
        config.locator.blurKernelSize,
      ), 0);
      try {
        for (final thresholds in config.locator.cannyThresholds) {
          final edges = cv.canny(blurred, thresholds.$1, thresholds.$2);
          final kernel = cv.getStructuringElement(cv.MORPH_RECT, (
            config.locator.morphologyKernelSize,
            config.locator.morphologyKernelSize,
          ));
          final closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);
          try {
            final (contours, hierarchy) = cv.findContours(
              closed,
              cv.RETR_LIST,
              cv.CHAIN_APPROX_SIMPLE,
            );
            try {
              for (final contour in contours) {
                final perimeter = cv.arcLength(contour, true);
                if (perimeter < config.locator.minimumContourPerimeter) {
                  continue;
                }
                final approximation = cv.approxPolyDP(
                  contour,
                  perimeter * config.locator.polygonApproximationFactor,
                  true,
                );
                try {
                  if (approximation.length != 4 ||
                      !cv.isContourConvex(approximation)) {
                    continue;
                  }
                  final ordered = _orderCorners([
                    for (final point in approximation.toList())
                      _CvPoint(point.x.toDouble(), point.y.toDouble()),
                  ]);
                  final candidate = _scoreGenericLcdCandidate(
                    ordered,
                    source.cols,
                    source.rows,
                    config.locator,
                  );
                  if (candidate != null &&
                      (best == null || candidate.score > best.score)) {
                    best = candidate;
                  }
                } finally {
                  approximation.dispose();
                }
              }
            } finally {
              contours.dispose();
              hierarchy.dispose();
            }
          } finally {
            edges.dispose();
            kernel.dispose();
            closed.dispose();
          }
        }
      } finally {
        blurred.dispose();
      }
    }
    final candidate = best;
    if (candidate == null) {
      final width = source.cols.toDouble();
      final height = source.rows.toDouble();
      // Manual calibration must remain available even when automatic contour
      // detection is uncertain. Start with a large central quadrilateral and
      // let the user place its four points on the actual inner LCD corners.
      return rectifyCalibrationLcd(photoBytes, [
        (width * 0.16, height * 0.14),
        (width * 0.84, height * 0.14),
        (width * 0.84, height * 0.88),
        (width * 0.16, height * 0.88),
      ]);
    }
    final top = _distance(candidate.corners[0], candidate.corners[1]);
    final bottom = _distance(candidate.corners[3], candidate.corners[2]);
    final left = _distance(candidate.corners[0], candidate.corners[3]);
    final right = _distance(candidate.corners[1], candidate.corners[2]);
    final ratio = ((top + bottom) / 2) / ((left + right) / 2);
    const canonicalHeight = 960;
    final canonicalWidth = (canonicalHeight * ratio).round().clamp(420, 1100);
    final sourcePoints = cv.VecPoint2f.fromList([
      for (final point in candidate.corners) cv.Point2f(point.x, point.y),
    ]);
    final destinationPoints = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(canonicalWidth - 1, 0),
      cv.Point2f(canonicalWidth - 1, canonicalHeight - 1),
      cv.Point2f(0, canonicalHeight - 1),
    ]);
    final transform = cv.getPerspectiveTransform2f(
      sourcePoints,
      destinationPoints,
    );
    final rectified = cv.warpPerspective(source, transform, (
      canonicalWidth,
      canonicalHeight,
    ));
    try {
      return CalibrationLcdResult(
        rectifiedBytes: _encodeJpeg(rectified),
        imageWidth: source.cols,
        imageHeight: source.rows,
        corners: [for (final point in candidate.corners) (point.x, point.y)],
        canonicalWidth: canonicalWidth,
        canonicalHeight: canonicalHeight,
      );
    } finally {
      sourcePoints.dispose();
      destinationPoints.dispose();
      transform.dispose();
      rectified.dispose();
    }
  } finally {
    source.dispose();
    gray.dispose();
    equalized.dispose();
  }
}

/// Rectifies a calibration photo using four user-confirmed LCD corners in the
/// order top-left, top-right, bottom-right, bottom-left.
CalibrationLcdResult rectifyCalibrationLcd(
  Uint8List photoBytes,
  List<(double, double)> corners,
) {
  if (corners.length != 4) {
    throw const FormatException('Four LCD corners are required');
  }
  final source = cv.imdecode(photoBytes, cv.IMREAD_COLOR);
  if (source.isEmpty) {
    source.dispose();
    throw const FormatException('Unable to read the photograph');
  }
  final ordered = [for (final point in corners) _CvPoint(point.$1, point.$2)];
  final top = _distance(ordered[0], ordered[1]);
  final bottom = _distance(ordered[3], ordered[2]);
  final left = _distance(ordered[0], ordered[3]);
  final right = _distance(ordered[1], ordered[2]);
  final ratio = ((top + bottom) / 2) / ((left + right) / 2);
  if (!ratio.isFinite || ratio < 0.2 || ratio > 2.5) {
    source.dispose();
    throw const FormatException('LCD corners form an invalid rectangle');
  }
  const canonicalHeight = 960;
  final canonicalWidth = (canonicalHeight * ratio).round().clamp(320, 1400);
  final sourcePoints = cv.VecPoint2f.fromList([
    for (final point in ordered) cv.Point2f(point.x, point.y),
  ]);
  final destinationPoints = cv.VecPoint2f.fromList([
    cv.Point2f(0, 0),
    cv.Point2f(canonicalWidth - 1, 0),
    cv.Point2f(canonicalWidth - 1, canonicalHeight - 1),
    cv.Point2f(0, canonicalHeight - 1),
  ]);
  final transform = cv.getPerspectiveTransform2f(
    sourcePoints,
    destinationPoints,
  );
  final rectified = cv.warpPerspective(source, transform, (
    canonicalWidth,
    canonicalHeight,
  ));
  try {
    return CalibrationLcdResult(
      rectifiedBytes: _encodeJpeg(rectified),
      imageWidth: source.cols,
      imageHeight: source.rows,
      corners: corners,
      canonicalWidth: canonicalWidth,
      canonicalHeight: canonicalHeight,
    );
  } finally {
    source.dispose();
    sourcePoints.dispose();
    destinationPoints.dispose();
    transform.dispose();
    rectified.dispose();
  }
}

_LcdCandidate? _scoreGenericLcdCandidate(
  List<_CvPoint> corners,
  int imageWidth,
  int imageHeight,
  LcdLocatorConfig config,
) {
  final areaFraction = _polygonArea(corners) / (imageWidth * imageHeight);
  if (areaFraction < config.minimumAreaFraction ||
      areaFraction > config.maximumAreaFraction) {
    return null;
  }
  final top = _distance(corners[0], corners[1]);
  final right = _distance(corners[1], corners[2]);
  final bottom = _distance(corners[2], corners[3]);
  final left = _distance(corners[3], corners[0]);
  if ([
    top,
    right,
    bottom,
    left,
  ].any((length) => length < config.minimumSideLength)) {
    return null;
  }
  final ratio = ((top + bottom) / 2) / ((left + right) / 2);
  if (ratio < 0.28 || ratio > 1.8) return null;
  final oppositeWidth = math.min(top, bottom) / math.max(top, bottom);
  final oppositeHeight = math.min(left, right) / math.max(left, right);
  if (oppositeWidth < config.minimumOppositeSideRatio ||
      oppositeHeight < config.minimumOppositeSideRatio) {
    return null;
  }
  final rectangularity = (oppositeWidth + oppositeHeight) / 2;
  final size = areaFraction.clamp(0.0, 0.45) / 0.45;
  return _LcdCandidate(corners, rectangularity * 1.6 + size);
}

/// Locates the fixed Microlife device from its housing details, then rectifies
/// the LCD. The changing LCD contents are masked in the reference image.
Uint8List locateAndRectifyLcd(
  Uint8List photoBytes,
  Uint8List referenceBytes,
  LcdDeviceProfile deviceProfile,
  CvConfig config,
) {
  final source = cv.imdecode(photoBytes, cv.IMREAD_COLOR);
  if (source.isEmpty) {
    source.dispose();
    throw const FormatException('Не удалось прочитать фотографию');
  }

  final directLcd = _locateLcdDirectly(source, deviceProfile, config.locator);
  if (directLcd != null) {
    try {
      return _encodeJpeg(directLcd);
    } finally {
      directLcd.dispose();
      source.dispose();
    }
  }

  final reference = cv.imdecode(referenceBytes, cv.IMREAD_COLOR);
  if (reference.isEmpty) {
    source.dispose();
    reference.dispose();
    throw const FormatException('Не удалось прочитать эталон тонометра');
  }

  final sourceGray = cv.cvtColor(source, cv.COLOR_BGR2GRAY);
  final referenceGray = cv.cvtColor(reference, cv.COLOR_BGR2GRAY);
  final referenceMask = cv.Mat.fromScalar(
    reference.rows,
    reference.cols,
    cv.MatType.CV_8UC1,
    cv.Scalar.all(255),
  );
  // Expanded bounding box around the calibrated LCD quadrilateral.
  final referenceMaskRect = deviceProfile.referenceMask;
  cv.rectangle(
    referenceMask,
    cv.Rect(
      referenceMaskRect.x,
      referenceMaskRect.y,
      referenceMaskRect.width,
      referenceMaskRect.height,
    ),
    cv.Scalar.all(0),
    thickness: cv.FILLED,
  );

  final locator = config.locator;
  final sift = cv.SIFT.create(
    nfeatures: locator.siftFeatures,
    contrastThreshold: locator.siftContrastThreshold,
  );
  final matcher = cv.BFMatcher.create(type: cv.NORM_L2);
  final (referencePoints, referenceDescriptors) = sift.detectAndCompute(
    referenceGray,
    referenceMask,
  );
  final (sourcePoints, sourceDescriptors) = sift.detectAndCompute(
    sourceGray,
    cv.Mat.empty(),
  );

  try {
    if (referenceDescriptors.isEmpty || sourceDescriptors.isEmpty) {
      throw const LcdNotFoundException('Прибор не найден в кадре');
    }
    final pairs = matcher.knnMatch(referenceDescriptors, sourceDescriptors, 2);
    final good = <cv.DMatch>[];
    for (final pair in pairs) {
      if (pair.length == 2 &&
          pair[0].distance < locator.featureMatchRatio * pair[1].distance) {
        good.add(pair[0]);
      }
    }
    if (good.length < locator.minimumGoodMatches) {
      throw const LcdNotFoundException(
        'Прибор не найден. Отодвиньте телефон и снимите его целиком',
      );
    }

    final from = <double>[];
    final to = <double>[];
    for (final match in good) {
      final referencePoint = referencePoints[match.queryIdx];
      final sourcePoint = sourcePoints[match.trainIdx];
      from.addAll([referencePoint.x, referencePoint.y]);
      to.addAll([sourcePoint.x, sourcePoint.y]);
    }
    final fromMat = cv.Mat.fromList(good.length, 1, cv.MatType.CV_32FC2, from);
    final toMat = cv.Mat.fromList(good.length, 1, cv.MatType.CV_32FC2, to);
    final inlierMask = cv.Mat.empty();
    final homography = cv.findHomography(
      fromMat,
      toMat,
      method: cv.RANSAC,
      ransacReprojThreshold: locator.ransacReprojectionThreshold,
      mask: inlierMask,
      maxIters: locator.ransacMaximumIterations,
      confidence: locator.ransacConfidence,
    );
    final inliers = inlierMask.isEmpty ? 0 : cv.countNonZero(inlierMask);
    if (homography.isEmpty ||
        inliers < locator.minimumInliers ||
        inliers / good.length < locator.minimumInlierRatio) {
      throw const LcdNotFoundException(
        'Не удалось уверенно найти экран. Снимите прибор целиком ещё раз',
      );
    }

    final referenceLcd = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, <double>[
      for (final point in deviceProfile.referenceLcdPoints) ...[
        point.$1,
        point.$2,
      ],
    ]);
    final projected = cv.perspectiveTransform(referenceLcd, homography);
    final values = projected.toList3D();
    final lcdPoints = cv.VecPoint2f.fromList([
      for (final row in values)
        cv.Point2f(row[0][0].toDouble(), row[0][1].toDouble()),
    ]);
    final canonical = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(deviceProfile.canonicalWidth - 1, 0),
      cv.Point2f(
        deviceProfile.canonicalWidth - 1,
        deviceProfile.canonicalHeight - 1,
      ),
      cv.Point2f(0, deviceProfile.canonicalHeight - 1),
    ]);
    final transform = cv.getPerspectiveTransform2f(lcdPoints, canonical);
    final rectified = cv.warpPerspective(source, transform, (
      deviceProfile.canonicalWidth,
      deviceProfile.canonicalHeight,
    ));
    final result = _encodeJpeg(rectified);

    fromMat.dispose();
    toMat.dispose();
    inlierMask.dispose();
    homography.dispose();
    referenceLcd.dispose();
    projected.dispose();
    lcdPoints.dispose();
    canonical.dispose();
    transform.dispose();
    rectified.dispose();
    return result;
  } finally {
    source.dispose();
    reference.dispose();
    sourceGray.dispose();
    referenceGray.dispose();
    referenceMask.dispose();
    sift.dispose();
    matcher.dispose();
    referencePoints.dispose();
    referenceDescriptors.dispose();
    sourcePoints.dispose();
    sourceDescriptors.dispose();
  }
}

Uint8List _encodeJpeg(cv.Mat image) {
  final (encoded, buffer) = cv.imencode('.jpg', image);
  if (!encoded) {
    throw const FormatException('Не удалось подготовить изображение LCD');
  }
  return Uint8List.fromList(buffer);
}

cv.Mat? _locateLcdDirectly(
  cv.Mat source,
  LcdDeviceProfile deviceProfile,
  LcdLocatorConfig config,
) {
  final gray = cv.cvtColor(source, cv.COLOR_BGR2GRAY);
  final equalized = cv.equalizeHist(gray);
  _LcdCandidate? best;
  try {
    for (final variant in [gray, equalized]) {
      final blurred = cv.gaussianBlur(variant, (
        config.blurKernelSize,
        config.blurKernelSize,
      ), 0);
      try {
        for (final thresholds in config.cannyThresholds) {
          final edges = cv.canny(blurred, thresholds.$1, thresholds.$2);
          final kernel = cv.getStructuringElement(cv.MORPH_RECT, (
            config.morphologyKernelSize,
            config.morphologyKernelSize,
          ));
          final closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);
          try {
            final (contours, hierarchy) = cv.findContours(
              closed,
              cv.RETR_LIST,
              cv.CHAIN_APPROX_SIMPLE,
            );
            try {
              for (final contour in contours) {
                final perimeter = cv.arcLength(contour, true);
                if (perimeter < config.minimumContourPerimeter) continue;
                final approximation = cv.approxPolyDP(
                  contour,
                  perimeter * config.polygonApproximationFactor,
                  true,
                );
                try {
                  if (approximation.length != 4 ||
                      !cv.isContourConvex(approximation)) {
                    continue;
                  }
                  final points = approximation.toList();
                  final ordered = _orderCorners([
                    for (final point in points)
                      _CvPoint(point.x.toDouble(), point.y.toDouble()),
                  ]);
                  final candidate = _scoreLcdCandidate(
                    ordered,
                    source.cols,
                    source.rows,
                    deviceProfile,
                    config,
                  );
                  if (candidate != null &&
                      (best == null || candidate.score > best.score)) {
                    best = candidate;
                  }
                } finally {
                  approximation.dispose();
                }
              }
            } finally {
              contours.dispose();
              hierarchy.dispose();
            }
          } finally {
            edges.dispose();
            kernel.dispose();
            closed.dispose();
          }
        }
      } finally {
        blurred.dispose();
      }
    }
    if (best == null || best.score < config.minimumCandidateScore) return null;
    final sourcePoints = cv.VecPoint2f.fromList([
      for (final point in best.corners) cv.Point2f(point.x, point.y),
    ]);
    final destinationPoints = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(deviceProfile.canonicalWidth - 1, 0),
      cv.Point2f(
        deviceProfile.canonicalWidth - 1,
        deviceProfile.canonicalHeight - 1,
      ),
      cv.Point2f(0, deviceProfile.canonicalHeight - 1),
    ]);
    final transform = cv.getPerspectiveTransform2f(
      sourcePoints,
      destinationPoints,
    );
    final result = cv.warpPerspective(source, transform, (
      deviceProfile.canonicalWidth,
      deviceProfile.canonicalHeight,
    ));
    sourcePoints.dispose();
    destinationPoints.dispose();
    transform.dispose();
    return result;
  } finally {
    gray.dispose();
    equalized.dispose();
  }
}

_LcdCandidate? _scoreLcdCandidate(
  List<_CvPoint> corners,
  int imageWidth,
  int imageHeight,
  LcdDeviceProfile deviceProfile,
  LcdLocatorConfig config,
) {
  final area = _polygonArea(corners);
  final imageArea = imageWidth * imageHeight;
  final areaFraction = area / imageArea;
  if (areaFraction < config.minimumAreaFraction ||
      areaFraction > config.maximumAreaFraction) {
    return null;
  }

  final top = _distance(corners[0], corners[1]);
  final right = _distance(corners[1], corners[2]);
  final bottom = _distance(corners[2], corners[3]);
  final left = _distance(corners[3], corners[0]);
  if ([
    top,
    right,
    bottom,
    left,
  ].any((length) => length < config.minimumSideLength)) {
    return null;
  }
  final observedRatio = ((top + bottom) / 2) / ((left + right) / 2);
  if (observedRatio < config.minimumObservedRatio ||
      observedRatio > config.maximumObservedRatio) {
    return null;
  }
  final oppositeWidthRatio = top < bottom ? top / bottom : bottom / top;
  final oppositeHeightRatio = left < right ? left / right : right / left;
  if (oppositeWidthRatio < config.minimumOppositeSideRatio ||
      oppositeHeightRatio < config.minimumOppositeSideRatio) {
    return null;
  }

  final expectedRatio =
      deviceProfile.canonicalWidth / deviceProfile.canonicalHeight;
  final ratioScore =
      1 / (1 + config.ratioScoreWeight * (observedRatio - expectedRatio).abs());
  final parallelScore = (oppositeWidthRatio + oppositeHeightRatio) / 2;
  final sizeScore =
      areaFraction.clamp(0.0, config.fullSizeAreaFraction) /
      config.fullSizeAreaFraction;
  return _LcdCandidate(
    corners,
    ratioScore +
        parallelScore * config.parallelScoreWeight +
        sizeScore * config.sizeScoreWeight,
  );
}

List<_CvPoint> _orderCorners(List<_CvPoint> points) {
  final topLeft = points.reduce((a, b) => a.x + a.y <= b.x + b.y ? a : b);
  final bottomRight = points.reduce((a, b) => a.x + a.y >= b.x + b.y ? a : b);
  final topRight = points.reduce((a, b) => a.x - a.y >= b.x - b.y ? a : b);
  final bottomLeft = points.reduce((a, b) => a.x - a.y <= b.x - b.y ? a : b);
  return [topLeft, topRight, bottomRight, bottomLeft];
}

double _distance(_CvPoint first, _CvPoint second) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _polygonArea(List<_CvPoint> points) {
  var sum = 0.0;
  for (var index = 0; index < points.length; index++) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    sum += current.x * next.y - next.x * current.y;
  }
  return sum.abs() / 2;
}

class _CvPoint {
  const _CvPoint(this.x, this.y);
  final double x;
  final double y;
}

class _LcdCandidate {
  const _LcdCandidate(this.corners, this.score);

  final List<_CvPoint> corners;
  final double score;
}
