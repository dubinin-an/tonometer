# Tech stack

- Flutter 3.47.0 stable, Dart 3.13.0; project SDK constraint `^3.13.0`. Repository docs use SDK at `/Users/dan/flutter/bin/{flutter,dart}`.
- Material 3 UI; Flutter localization generation with ARB files for ru/en/es.
- Drift 2.34.x + drift_flutter/native SQLite; generated schema code via drift_dev + build_runner.
- Camera stack: camera 0.12.x with pinned camera_android_camerax 0.7.4+2.
- Image/CV: image 4.9.x and opencv_dart 2.2.x; OpenCV hook includes imgcodecs, imgproc, features2d, calib3d and CMake 3.22.1.
- Notifications/time: flutter_local_notifications, timezone, flutter_timezone.
- Export/share: share_plus, path_provider, path.
- Tests use flutter_test; analyzer rules inherit flutter_lints 6.x.