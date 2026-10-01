import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/services/cv_config.dart';

void main() {
  test('loads Microlife LCD geometry from its profile', () async {
    final profile = LcdDeviceProfile.fromJsonString(
      await File('assets/profiles/microlife_test_tonometer.profile.json')
          .readAsString(),
    );

    expect((profile.canonicalWidth, profile.canonicalHeight), (640, 960));
    expect(profile.referenceAsset, '1000056343.jpg');
    expect(profile.referenceLcdPoints, hasLength(4));
    expect(profile.referenceLcdPoints.first, (322.0, 470.0));
    expect(profile.referenceMask.width, 540);
  });
}
