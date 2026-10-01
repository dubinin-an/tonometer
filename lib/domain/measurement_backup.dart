class MeasurementBackup {
  const MeasurementBackup({required this.measurements, required this.series});

  final List<MeasurementBackupEntry> measurements;
  final Map<String, MeasurementSeriesBackup> series;

  int get seriesCount => series.length;
}

class MeasurementBackupEntry {
  const MeasurementBackupEntry({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.armSide,
    required this.measuredAt,
    required this.createdAt,
    this.comment,
    this.seriesKey,
    this.sequenceNumber,
  });

  final int systolic;
  final int diastolic;
  final int pulse;
  final String armSide;
  final DateTime measuredAt;
  final DateTime createdAt;
  final String? comment;
  final String? seriesKey;
  final int? sequenceNumber;
}

class MeasurementSeriesBackup {
  const MeasurementSeriesBackup({
    required this.key,
    required this.startedAt,
    required this.completedAt,
    this.comment,
  });

  final String key;
  final DateTime startedAt;
  final DateTime completedAt;
  final String? comment;
}
