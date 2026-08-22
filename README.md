# Route Performance Tracker

Route Performance Tracker is a local-first Flutter app for delivery drivers who want a personal record of route pace, checkpoints, delays, finish-time forecasts, route difficulty, evidence, and historical performance.

## Current version

**1.0.0 release candidate**

Core route tracking is stored on-device with SQLite and remains usable without an account or cloud connection. Accounts are used for AI usage, cloud features, and subscription restoration.

## Core features

- Route setup without starting the delivery clock
- Fast stop checkpoints with automatic timestamps
- Raw and adjusted pace, segment pace, progress, and stops remaining
- Finish-time forecasting using today's route and personal historical pace
- Route events/delays with notes
- Photo/screenshot evidence stored locally
- Multi-screenshot import with on-device OCR
- Secure AI-assisted route-map analysis
- Transparent route difficulty model
- Completed-route History
- Basic Free analytics and advanced Pro analytics
- Supabase accounts and Pro-gated cloud route backup/restore
- Google Play subscription architecture with server-side verification
- Server-enforced Free AI quota: 3 successful analyses/month for signed-in Free accounts

## Free and Pro

Free keeps the core tracker useful: local routes, checkpoints, events, evidence, basic forecasts/stats, 7-day basic analytics, and 3 AI analyses per month for signed-in users.

Pro adds expanded/fair-use AI analysis, advanced historical analytics, cloud backup/restore, and expanded reporting features.

Target US pricing is **$6.99/month** or **$66.99/year**. Google Play is the source of truth for localized price and billing terms.

## Important 1.0 boundaries

- Original evidence image files are local-only and are not included in cloud route backup/restore.
- AI, cloud, account, and subscription actions require connectivity.
- AI-extracted values and forecasts are estimates and require user review.
- Android/Google Play is the first release target; iOS billing is not enabled in the Android-first release.

## Local development

Target toolchain: **Flutter 3.47.1 / Dart 3.13.1**.

```bash
flutter create . --platforms=android --org com.routeperformancetracker
flutter pub get
flutter analyze
flutter test
flutter run
```

Generated native platform folders are intentionally not committed. CI generates the Android runner before testing/building.

## Automated builds

GitHub Actions validates backend syntax/tests, Flutter analysis/tests, and builds a vision-enabled debug APK. A manual release job can build a signed Android App Bundle after the Android upload keystore secrets are configured.

Release/test/policy material is in `docs/`.

## Independence

Route Performance Tracker is an independent project. It is not affiliated with or endorsed by Amazon, any DSP, delivery company, or employer.
