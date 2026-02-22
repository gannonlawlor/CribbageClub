#!/bin/bash
# Run Android app in debug mode against alpha server (Tailscale)
# Pass a device id as $1 to target a specific device
set -e
cd "$(dirname "$0")/.."
flutter run --flavor alpha --dart-define-from-file=dart_define/alpha.json ${1:+-d "$1"}
