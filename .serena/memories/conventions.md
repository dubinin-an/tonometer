# Code conventions

- Follow `package:flutter_lints/flutter.yaml`; Dart formatter is authoritative. Analyzer excludes generated/platform trees listed in `analysis_options.yaml`.
- Dart files use snake_case; types UpperCamelCase; private members prefixed `_`; prefer `const` constructors/widgets where possible.
- Dependency wiring is explicit through constructors from `main.dart`/`TonometerApp`; repositories/services are passed into screens rather than fetched from globals.
- Domain drafts are immutable value holders with final fields. Persistence operations accept drafts and map them to Drift companions.
- Database changes require: increment `schemaVersion`, add ordered migration guarded by `from < N`, regenerate `app_database.g.dart`, and test with in-memory `NativeDatabase`. Foreign keys are enabled in `beforeOpen`.
- Multi-row writes that must remain consistent use Drift transactions (measurement series is atomic).
- UI text belongs in ARB localization resources, not inline strings; `app_ru.arb` is the localization template. Preserve ru/en/es coverage and regenerate outputs.
- Recognition is deterministic and profile-driven; preserve mandatory editable confirmation and manual-entry fallback. Calibration claims must be backed by fixture/real-photo evidence.
- Tests use `flutter_test`, descriptive behavior names, explicit fixed timestamps, in-memory database setup/teardown, and fixture assets under `test/fixtures/`.
- Do not edit generated files such as `lib/data/app_database.g.dart` or `lib/l10n/app_localizations*.dart` directly.