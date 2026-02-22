#!/bin/bash
# Run Android app in debug mode against local backend (localhost:8080)
# Pass a device id as $1 to target a specific device
set -e
cd "$(dirname "$0")/.."
flutter run --flavor dev ${1:+-d "$1"}
