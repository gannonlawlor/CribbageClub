#!/bin/bash
# Build Android alpha release APK and App Bundle
set -e
cd "$(dirname "$0")/.."

echo "Building APK..."
flutter build apk --flavor alpha --dart-define-from-file=dart_define/alpha.json "$@"

echo ""
echo "Building App Bundle..."
flutter build appbundle --flavor alpha --dart-define-from-file=dart_define/alpha.json "$@"

echo ""
echo "Outputs:"
echo "  APK: build/app/outputs/flutter-apk/app-alpha-release.apk"
echo "  AAB: build/app/outputs/bundle/alphaRelease/app-alpha-release.aab"
