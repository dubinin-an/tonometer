import 'dart:typed_data';

class TonometerProfileSummary {
  const TonometerProfileSummary({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.builtIn,
  });

  final String id;
  final String name;
  final String? manufacturer;
  final String? model;
  final bool builtIn;
}

class TonometerProfileBundle {
  const TonometerProfileBundle({
    required this.json,
    required this.referenceBytes,
  });

  final String json;
  final Uint8List referenceBytes;
}

class NormalizedRegion {
  const NormalizedRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, double> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}
