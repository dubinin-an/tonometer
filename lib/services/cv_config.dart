import 'dart:convert';

/// Tunable parameters of the image-processing pipeline.
///
/// Device geometry and measurement fields belong to the JSON device profile;
/// these values describe how the generic CV algorithms search and classify.
class CvConfig {
  const CvConfig({
    this.profileAsset = 'assets/profiles/microlife_test_tonometer.profile.json',
    this.previewAdaptiveOffset = 4,
    this.fieldThresholdAdjustments = const [-8, 0, 8],
    this.fieldAdaptiveOffsets = const [8, 4],
    this.adaptiveRadius = 20,
    this.fieldExpansionPixels = 10,
    this.binaryMajorityThreshold = 5,
    this.contrastLowPercentile = 0.02,
    this.contrastHighPercentile = 0.98,
    this.minimumContrastRange = 8,
    this.minimumComponentAreaFraction = 0.002,
    this.maximumComponentAreaFraction = 0.22,
    this.horizontalAspectRatio = 1.45,
    this.verticalAspectRatio = 0.72,
    this.horizontalSegmentTolerance = 0.23,
    this.horizontalSegmentCenters = const (0.08, 0.50, 0.92),
    this.maximumVerticalOnlyComponents = 3,
    this.verticalOnlyDigitHorizontalBounds = const (0.18, 0.82),
    this.maximumDigitSegmentDistance = 1,
    this.locator = const LcdLocatorConfig(),
  });

  final String profileAsset;
  final int previewAdaptiveOffset;
  final List<int> fieldThresholdAdjustments;
  final List<int> fieldAdaptiveOffsets;
  final int adaptiveRadius;
  final int fieldExpansionPixels;
  final int binaryMajorityThreshold;
  final double contrastLowPercentile;
  final double contrastHighPercentile;
  final int minimumContrastRange;
  final double minimumComponentAreaFraction;
  final double maximumComponentAreaFraction;
  final double horizontalAspectRatio;
  final double verticalAspectRatio;
  final double horizontalSegmentTolerance;
  final (double, double, double) horizontalSegmentCenters;
  final int maximumVerticalOnlyComponents;
  final (double, double) verticalOnlyDigitHorizontalBounds;
  final int maximumDigitSegmentDistance;
  final LcdLocatorConfig locator;
}

class LcdLocatorConfig {
  const LcdLocatorConfig({
    this.blurKernelSize = 5,
    this.morphologyKernelSize = 7,
    this.cannyThresholds = const [(25.0, 80.0), (50.0, 150.0)],
    this.minimumContourPerimeter = 200,
    this.polygonApproximationFactor = 0.025,
    this.minimumAreaFraction = 0.035,
    this.maximumAreaFraction = 0.75,
    this.minimumSideLength = 50,
    this.minimumObservedRatio = 0.32,
    this.maximumObservedRatio = 1.05,
    this.minimumOppositeSideRatio = 0.48,
    this.minimumCandidateScore = 1.3,
    this.ratioScoreWeight = 4,
    this.parallelScoreWeight = 0.8,
    this.sizeScoreWeight = 0.45,
    this.fullSizeAreaFraction = 0.35,
    this.siftFeatures = 3500,
    this.siftContrastThreshold = 0.025,
    this.featureMatchRatio = 0.72,
    this.minimumGoodMatches = 12,
    this.ransacReprojectionThreshold = 4,
    this.ransacMaximumIterations = 4000,
    this.ransacConfidence = 0.999,
    this.minimumInliers = 12,
    this.minimumInlierRatio = 0.30,
  });

  final int blurKernelSize;
  final int morphologyKernelSize;
  final List<(double, double)> cannyThresholds;
  final double minimumContourPerimeter;
  final double polygonApproximationFactor;
  final double minimumAreaFraction;
  final double maximumAreaFraction;
  final double minimumSideLength;
  final double minimumObservedRatio;
  final double maximumObservedRatio;
  final double minimumOppositeSideRatio;
  final double minimumCandidateScore;
  final double ratioScoreWeight;
  final double parallelScoreWeight;
  final double sizeScoreWeight;
  final double fullSizeAreaFraction;
  final int siftFeatures;
  final double siftContrastThreshold;
  final double featureMatchRatio;
  final int minimumGoodMatches;
  final double ransacReprojectionThreshold;
  final int ransacMaximumIterations;
  final double ransacConfidence;
  final int minimumInliers;
  final double minimumInlierRatio;
}

/// Device-specific geometry loaded from the JSON profile.
class LcdDeviceProfile {
  const LcdDeviceProfile({
    required this.canonicalWidth,
    required this.canonicalHeight,
    required this.referenceAsset,
    required this.referenceMask,
    required this.referenceLcdPoints,
  });

  factory LcdDeviceProfile.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final normalization = json['normalization'] as Map<String, dynamic>;
    final reference = json['calibrationReference'] as Map<String, dynamic>;
    final mask = reference['featureMaskRect'] as Map<String, dynamic>;
    final quadrilateral =
        reference['innerLcdQuadrilateral'] as Map<String, dynamic>;

    (double, double) point(String name) {
      final value = quadrilateral[name] as Map<String, dynamic>;
      return ((value['x'] as num).toDouble(), (value['y'] as num).toDouble());
    }

    return LcdDeviceProfile(
      canonicalWidth: normalization['canonicalWidth'] as int,
      canonicalHeight: normalization['canonicalHeight'] as int,
      referenceAsset: reference['asset'] as String?,
      referenceMask: (
        x: mask['x'] as int,
        y: mask['y'] as int,
        width: mask['width'] as int,
        height: mask['height'] as int,
      ),
      referenceLcdPoints: [
        point('topLeft'),
        point('topRight'),
        point('bottomRight'),
        point('bottomLeft'),
      ],
    );
  }

  final int canonicalWidth;
  final int canonicalHeight;
  final String? referenceAsset;
  final ({int x, int y, int width, int height}) referenceMask;
  final List<(double, double)> referenceLcdPoints;
}
