import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/services/automatic_lcd_locator.dart';
import 'package:tonometer_mvp/services/cv_config.dart';

void main() {
  test('finds and rectifies the LCD in all supplied photos', () async {
    final reference = await File('1000056343.jpg').readAsBytes();
    final profile = LcdDeviceProfile.fromJsonString(
      await File('assets/profiles/microlife_test_tonometer.profile.json')
          .readAsString(),
    );
    const config = CvConfig();

    for (var index = 1; index <= 6; index++) {
      final photo = await File('100005634$index.jpg').readAsBytes();
      final rectified = locateAndRectifyLcd(photo, reference, profile, config);
      expect(rectified, isNotEmpty, reason: '100005634$index.jpg');
    }
  });
}
