# Task completion

For Dart/Flutter code changes:

1. Format touched Dart files: `/Users/dan/flutter/bin/dart format <paths>`.
2. If Drift tables/migrations or ARB localization inputs changed, regenerate: `/Users/dan/flutter/bin/dart run build_runner build`.
3. Static checks: `/Users/dan/flutter/bin/flutter analyze`.
4. Tests: `/Users/dan/flutter/bin/flutter test`.
5. For changes affecting Android integration, camera/CV native hooks, notifications, or release viability, also build: `/Users/dan/flutter/bin/flutter build apk --debug`.

Focused iteration may run the affected test first, but full analyze + test is the handoff baseline. Recognition changes must include the fixture test; the current reference expectation is SYS/DIA/pulse = 143/90/90. Database changes require migration coverage and regenerated Drift code. UI changes must preserve text scaling, TalkBack semantics, and >=48 dp tap targets.