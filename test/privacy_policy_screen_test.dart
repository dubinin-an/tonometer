import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/ui/privacy_policy_screen.dart';

import 'test_app_harness.dart';

void main() {
  testWidgets('privacy page explains local processing and medical limits', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(child: const PrivacyPolicyScreen()),
    );

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Camera and photos'), findsOneWidget);
    expect(find.text('Export and backup'), findsOneWidget);
    expect(find.textContaining('not a medical device'), findsOneWidget);
  });
}
