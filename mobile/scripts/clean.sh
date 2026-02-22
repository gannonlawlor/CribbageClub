#!/bin/bash
# Clean build artifacts and rebuild dependencies
set -e
cd "$(dirname "$0")/.."
flutter clean
flutter pub get
echo ""
echo "Clean complete. Run scripts/codegen.sh to regenerate model code."
