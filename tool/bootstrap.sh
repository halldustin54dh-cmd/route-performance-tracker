#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not on PATH. Install Flutter 3.44+ first."
  exit 1
fi

flutter --version
flutter create . --platforms=android,ios --org com.routeperformancetracker
flutter pub get

echo
echo "Bootstrap complete. Before Play Store release, verify Android targetSdk is 36+."
echo "Run: flutter doctor"
echo "Then: flutter run"
