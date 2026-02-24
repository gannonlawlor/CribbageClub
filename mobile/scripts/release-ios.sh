#!/bin/bash
# Release iOS build: version bump → build IPA → git commit + tag → push → TestFlight upload
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC="$MOBILE_DIR/pubspec.yaml"

# Defaults
BUMP_TYPE="minor"
DRY_RUN=false
SKIP_UPLOAD=false
AUTO_YES=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --patch)    BUMP_TYPE="patch"; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        --skip-upload) SKIP_UPLOAD=true; shift ;;
        --yes|-y)   AUTO_YES=true; shift ;;
        -h|--help)
            echo "Usage: release-ios.sh [--patch] [--dry-run] [--skip-upload]"
            echo ""
            echo "Flags:"
            echo "  --patch        Increment patch version instead of minor"
            echo "  --dry-run      Show what would happen without executing"
            echo "  --skip-upload  Build, commit, tag, push — but skip TestFlight upload"
            echo "  --yes, -y      Skip confirmation prompt"
            exit 0
            ;;
        *)
            echo "Unknown flag: $1"
            exit 1
            ;;
    esac
done

# --- Parse current version from pubspec.yaml ---
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: *//' | sed 's/+.*//')

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# --- Compute new version ---
if [[ "$BUMP_TYPE" == "patch" ]]; then
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
else
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
fi

TAG="v$NEW_VERSION"

# --- Confirmation ---
echo "iOS Release"
echo "==========="
echo ""
echo "  Current:  $CURRENT_VERSION"
echo "  New:      $NEW_VERSION"
echo "  Tag:      $TAG"
echo "  Bump:     $BUMP_TYPE"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] Would update pubspec.yaml: version: $NEW_VERSION"
    echo "[dry-run] Would run: flutter build ipa --flavor alpha --dart-define-from-file=dart_define/alpha.json --release"
    echo "[dry-run] Would commit pubspec.yaml with message: Release $TAG"
    echo "[dry-run] Would tag: $TAG"
    echo "[dry-run] Would push commit and tag to origin"
    if [[ "$SKIP_UPLOAD" == false ]]; then
        echo "[dry-run] Would upload to TestFlight via xcodebuild -exportArchive"
    else
        echo "[dry-run] Upload to TestFlight: skipped (--skip-upload)"
    fi
    echo ""
    echo "Dry run complete. No changes made."
    exit 0
fi

if [[ "$AUTO_YES" == false ]]; then
    read -r -p "Proceed? (y/n) " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# --- Check for clean working tree (except pubspec.lock) ---
if [[ -n $(git -C "$MOBILE_DIR" diff --name-only -- . ':!pubspec.lock') ]] || \
   [[ -n $(git -C "$MOBILE_DIR" diff --cached --name-only -- .) ]]; then
    echo "Error: Working tree has uncommitted changes in mobile/. Commit or stash first."
    exit 1
fi

# --- Update pubspec.yaml ---
echo ""
echo "Updating pubspec.yaml → version: $NEW_VERSION"
sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

# --- Build IPA ---
echo ""
echo "Building IPA..."
cd "$MOBILE_DIR"
flutter build ipa --flavor alpha --dart-define-from-file=dart_define/alpha.json --release

ARCHIVE_PATH="$MOBILE_DIR/build/ios/archive/Runner.xcarchive"
if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo "Error: Archive not found at $ARCHIVE_PATH"
    exit 1
fi
echo "Archive built: $ARCHIVE_PATH"

# --- Git commit + tag ---
echo ""
echo "Committing version bump and tagging $TAG..."
cd "$MOBILE_DIR/.."
git add mobile/pubspec.yaml
git commit -m "Release $TAG"
git tag "$TAG"

# --- Push ---
echo ""
echo "Pushing commit and tag to origin..."
git push origin HEAD
git push origin "$TAG"

# --- Upload to TestFlight ---
if [[ "$SKIP_UPLOAD" == true ]]; then
    echo ""
    echo "Upload to TestFlight skipped (--skip-upload)."
else
    echo ""
    echo "Uploading to TestFlight..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$SCRIPT_DIR/ExportOptions.plist" \
        -allowProvisioningUpdates \
        | tail -5
    echo "Upload complete!"
fi

echo ""
echo "Released $TAG"
