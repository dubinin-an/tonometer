import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/services/seven_segment_recognizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recognizes the Microlife calibration reference', () async {
    final bytes = await File('test/fixtures/microlife_reference.jpg')
        .readAsBytes();

    final result = await const SevenSegmentRecognizer()
        .recognizeCalibrationReference(bytes);

    expect(
      (result.systolic, result.diastolic, result.pulse, result.complete),
      (143, 90, 90, true),
      reason: result.rawDigits.toString(),
    );
  });
}
