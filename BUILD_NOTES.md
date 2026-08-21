# Build Notes — MVP 0.3

## Toolchain

Target Flutter release: **3.47.1** with Dart **3.13.1**.

The source repository does not depend on committed generated Android/iOS runner folders. Generate them from the installed Flutter SDK with:

```bash
flutter create . --platforms=android,ios --org com.routeperformancetracker
flutter pub get
```

Then validate:

```bash
flutter doctor
flutter analyze
flutter test
flutter run
```

## Android

For Google Play submission, verify the generated Android project targets **API 36 or newer**. The GitHub Actions workflow installs Android API 36 and builds a debug APK.

## iOS permissions

After generating the iOS project, add these permission strings to `ios/Runner/Info.plist` before device/App Store builds:

```xml
<key>NSCameraUsageDescription</key>
<string>Capture route and incident evidence.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select route screenshots and photos for your route record.</string>
```

## SQLite

Database schema version: **2**.

MVP 0.3 adds route-context columns and `route_evidence`. Existing schema-v1 databases migrate in place.

## Device QA checklist

1. Save route setup and close/reopen the app. Confirm the route persists.
2. Record the first stop only when delivery begins.
3. Add checkpoint 2 and confirm finish forecasting appears.
4. Add an event with delay minutes and confirm adjusted pace changes appropriately.
5. Capture/upload evidence and confirm a durable local copy appears in route activity.
6. Close/reopen mid-route and confirm checkpoints, events, and evidence remain.
7. Complete the final stop and confirm the route moves to History.
8. Start another route within 30 days and confirm the personal historical baseline is used.
9. Review Analytics for 7-day, 30-day, and all-time summaries.

## Automated CI

`.github/workflows/flutter-ci.yml` runs analysis, tests, and a debug Android build. The generated debug APK is uploaded as a GitHub Actions artifact.
