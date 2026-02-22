#!/bin/bash
# Run iOS app in debug mode against alpha server (Tailscale)
# Pass a device id as $1 to target a specific device, e.g.: ./ios-alpha.sh E124851F
set -e
cd "$(dirname "$0")/.."
flutter run --flavor alpha --dart-define-from-file=dart_define/alpha.json ${1:+-d "$1"}
