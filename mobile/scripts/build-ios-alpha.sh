#!/bin/bash
# Build iOS alpha release IPA (for TestFlight / archive)
set -e
cd "$(dirname "$0")/.."
flutter build ipa --flavor alpha --dart-define-from-file=dart_define/alpha.json "$@"
echo ""
echo "Archive complete. Open Xcode Organizer to upload to TestFlight:"
echo "  Xcode > Window > Organizer"
