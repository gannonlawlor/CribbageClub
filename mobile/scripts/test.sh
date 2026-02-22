#!/bin/bash
# Run tests and static analysis
set -e
cd "$(dirname "$0")/.."
echo "Running static analysis..."
flutter analyze
echo ""
echo "Running tests..."
flutter test "$@"
