# Suggested commands

Run from project root.

- Install packages: `/Users/dan/flutter/bin/flutter pub get`
- Generate Drift and localization outputs when schemas/ARB/config change: `/Users/dan/flutter/bin/dart run build_runner build`
- Run app: `/Users/dan/flutter/bin/flutter run`
- Format touched Dart files: `/Users/dan/flutter/bin/dart format <paths>`
- Analyze: `/Users/dan/flutter/bin/flutter analyze`
- Run all tests: `/Users/dan/flutter/bin/flutter test`
- Run one test: `/Users/dan/flutter/bin/flutter test test/<name>_test.dart`
- Build Android debug APK: `/Users/dan/flutter/bin/flutter build apk --debug`
- Check Serena memory references: `serena memories check`

Darwin note: Flutter commands may update files under `/Users/dan/flutter/bin/cache`; a restricted sandbox can block this even for `flutter --version`.