enum MeasurementArm {
  left('L'),
  right('R');

  const MeasurementArm(this.code);
  final String code;

  static MeasurementArm fromCode(String code) =>
      code == 'R' ? MeasurementArm.right : MeasurementArm.left;
}

class MeasurementDraft {
  const MeasurementDraft({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    this.arm = MeasurementArm.left,
    this.comment,
  });

  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime measuredAt;
  final MeasurementArm arm;
  final String? comment;
}
