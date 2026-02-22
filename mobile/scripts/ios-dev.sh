#!/bin/bash
# Run iOS app in debug mode against local backend (localhost:8080)
# Pass a device id as $1 to target a specific device, e.g.: ./ios-dev.sh E124851F
set -e
cd "$(dirname "$0")/.."
flutter run --flavor dev ${1:+-d "$1"}
