# Tonometer 1.0.0 release checklist

## Blocking tasks before the first Play upload

- [x] Permanent Android application ID: `app.tonometer.tonometer`.
- [x] Privacy-policy developer and contact: Aleksei Dubinin, `dubinin.a.n@gmail.com`.
- [x] Privacy policy: <https://dubinin-an.github.io/tonometer/privacy-policy.html>.
- [ ] Create and securely back up the Android upload keystore and its passwords.

The package ID changed from the MVP identifier. Existing local MVP installations are a separate Android application and their local data is not migrated automatically.

## Upload signing

Create the upload key outside source control:

```sh
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Copy `android/key.properties.example` to `android/key.properties`, insert the passwords, and keep both files outside backups that can be publicly accessed. Losing the upload key complicates future updates; keep an encrypted offline copy.

Build and verify the Play artifact:

```sh
/Users/dan/flutter/bin/flutter clean
/Users/dan/flutter/bin/flutter test
/Users/dan/flutter/bin/flutter analyze
/Users/dan/flutter/bin/flutter build appbundle --release
```

Expected artifact: `build/app/outputs/bundle/release/app-release.aab`.

## Google Play Console

- [ ] Create the application with the final app name and default English locale.
- [ ] Upload the signed AAB to Internal testing first.
- [ ] Add phone screenshots for English, Russian, and Spanish where practical.
- [ ] Add the 512×512 high-resolution icon and 1024×500 feature graphic.
- [ ] Paste localized listing text from `docs/play-store-listing.md`.
- [ ] Add the public privacy-policy URL.
- [ ] Complete Data safety: no developer data collection or sharing; user-initiated exports are local sharing actions.
- [ ] Complete the Health apps declaration as a health-management / blood-pressure journal.
- [ ] Declare that the app contains no ads.
- [ ] Complete target audience and content rating questionnaires.
- [ ] Review the exact-alarm permission declaration. Measurement reminders are the only use.
- [ ] Supply reviewer notes explaining that photos are processed locally and recognized values require user confirmation.
- [ ] Test install, upgrade, reminders after reboot, camera recognition, CSV backup/restore, and profile backup/restore from the Internal testing build.

## Release maintenance

- Increment the build number after every Play upload (`1.0.0+2`, `1.0.0+3`, …).
- Keep the privacy policy and Data safety answers synchronized with code changes.
- Re-run tests and create a database backup/restore compatibility test before every production release.
