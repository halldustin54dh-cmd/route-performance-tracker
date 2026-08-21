# Route Performance Tracker

Flutter MVP for delivery drivers who want a personal record of route pace, checkpoints, delays, finish-time forecasts, route difficulty, evidence, and historical performance.

## Current version

**MVP 0.3**

The app is local-first. Route data is stored on-device with SQLite and does not require an account or cloud connection for the core workflow.

## Current features

- Save route setup before delivery begins
- Separate **Record First Stop Now** action so loadout and drive time do not contaminate delivery pace
- Add lightweight checkpoints using only the current stop number; time is captured automatically
- Raw pace, adjusted pace, latest-segment pace, stops remaining, and progress
- Finish-time forecasting after checkpoint 2
- Automatic 30-day adjusted-pace baseline from completed local routes
- Forecast confidence that increases as checkpoints accumulate
- Route events with documented delay minutes and notes
- Photo/screenshot evidence from camera or gallery
- Evidence copied into app-controlled local storage
- Standardized evidence filenames
- Evidence categories for route documentation, incidents, vehicle/safety, and other
- Transparent route difficulty model with workload, complexity/travel, and context components
- Completed route History
- Analytics for 7 days, 30 days, and all time
- Common-event analysis
- SQLite v2 migration for existing MVP 0.2 databases

## Forecast model

Without history:

`60% cumulative pace + 40% latest segment pace`

When a 30-day personal baseline exists:

`50% cumulative pace + 30% latest segment pace + 20% 30-day adjusted pace`

The app intentionally compares the driver primarily against their own historical performance rather than assuming one universal delivery pace fits every route.

## Route difficulty

The score is intentionally transparent. It separates:

- **Workload:** stop count, packages/stop, locations/stop
- **Complexity and travel:** apartment, business, rural, multi-location share, average drive time, route spread
- **Context:** weather, access difficulty, documented delay

When there is not enough information, the app returns **Not enough data** rather than inventing a low difficulty score.

## Project structure

```text
lib/
  main.dart
  models/
    checkpoint.dart
    delivery_route.dart
    route_event.dart
    route_evidence.dart
  services/
    evidence_storage_service.dart
    route_difficulty_service.dart
    route_metrics_service.dart
    route_repository.dart
  screens/
    analytics_screen.dart
    history_detail_screen.dart
    home_screen.dart
    live_route_screen.dart
    start_route_screen.dart
  widgets/
    metric_tile.dart

test/
  route_difficulty_service_test.dart
  route_metrics_service_test.dart
```

## Local development

Target toolchain: **Flutter 3.47.1 / Dart 3.13.1**.

```bash
flutter create . --platforms=android,ios --org com.routeperformancetracker
flutter pub get
flutter analyze
flutter test
flutter run
```

The repository intentionally keeps generated native platform folders out of the initial source snapshot. `flutter create .` generates them from the installed Flutter SDK.

## Automated build

GitHub Actions runs on pushes and pull requests to `main` and performs:

1. Flutter setup
2. Android SDK/API 36 setup
3. Platform bootstrap
4. `flutter pub get`
5. `flutter analyze`
6. `flutter test`
7. `flutter build apk --debug`
8. Upload of the debug APK as a workflow artifact

## Next development phase

- Edit/correct checkpoints and events
- Better evidence management and evidence detail views
- Route report generation and PDF export
- Cloud accounts/sync
- Subscription entitlements
- Release signing and store deployment

## Independence

Route Performance Tracker is an independent project. It is not affiliated with or endorsed by Amazon or any delivery service provider.
