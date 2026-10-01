# Project core

- Android-first Flutter app: local blood-pressure journal for Microlife measurements.
- Entry point: `lib/main.dart`; composition/root theme/navigation: `lib/app.dart`.
- Layer map: `lib/ui/` screens/widgets; `lib/domain/` immutable input models; `lib/data/` Drift schema + repositories; `lib/services/` camera/LCD recognition, notifications, locale persistence, CSV export.
- Persistence is local SQLite via Drift. `AppDatabase` owns schema/migrations; repositories isolate UI from queries.
- Recognition invariant: fully on-device device-specific LCD localization + seven-segment decoding; every recognized SYS/DIA/pulse result must remain user-editable before save. Strategy/evidence: `docs/recognition-strategy.md`.
- Localization lives in `lib/l10n/*.arb`; configured by `l10n.yaml`; generated `app_localizations*.dart` files are build outputs.
- Accessibility is an MVP requirement: system text scaling, TalkBack, and tap targets >=48 dp.
- Read `mem:tech_stack` for pinned tools/dependencies, `mem:conventions` for codebase rules, `mem:suggested_commands` for daily commands, and `mem:task_completion` before handing off code changes.