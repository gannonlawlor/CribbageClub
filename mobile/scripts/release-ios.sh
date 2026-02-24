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

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --patch)    BUMP_TYPE="patch"; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        --skip-upload) SKIP_UPLOAD=true; shift ;;
        -h|--help)
            echo "Usage: release-ios.sh [--patch] [--dry-run] [--skip-upload]"
            echo ""
            echo "Flags:"
            echo "  --patch        Increment patch version instead of minor"
            echo "  --dry-run      Show what would happen without executing"
            echo "  --skip-upload  Build, commit, tag, push — but skip TestFlight upload"
            exit 0
            ;;
        *)
            echo "Unknown flag: $1"
            exit 1
            ;;
    esac
done

# --- Load App Store Connect credentials (unless skipping upload) ---
if [[ "$SKIP_UPLOAD" == false && "$DRY_RUN" == false ]]; then
    ENV_FILE="$SCRIPT_DIR/.release-env"
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$ENV_FILE"
    fi

    if [[ -z "$ASC_API_KEY_ID" || -z "$ASC_API_ISSUER_ID" || -z "$ASC_API_KEY_PATH" ]]; then
        echo "Error: App Store Connect credentials not configured."
        echo ""
        echo "Set these in $ENV_FILE or as environment variables:"
        echo "  ASC_API_KEY_ID=XXXXXXXXXX"
        echo "  ASC_API_ISSUER_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
        echo "  ASC_API_KEY_PATH=~/.appstoreconnect/AuthKey_XXXXXXXXXX.p8"
        exit 1
    fi

    # Expand ~ in key path
    ASC_API_KEY_PATH="${ASC_API_KEY_PATH/#\~/$HOME}"

    if [[ ! -f "$ASC_API_KEY_PATH" ]]; then
        echo "Error: API key file not found at $ASC_API_KEY_PATH"
        exit 1
    fi
fi

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
        echo "[dry-run] Would upload IPA to TestFlight via xcrun altool"
    else
        echo "[dry-run] Upload to TestFlight: skipped (--skip-upload)"
    fi
    echo ""
    echo "Dry run complete. No changes made."
    exit 0
fi

read -r -p "Proceed? (y/n) " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
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

IPA_PATH="$MOBILE_DIR/build/ios/ipa/Cribbage Club.ipa"
if [[ ! -f "$IPA_PATH" ]]; then
    # Try to find the IPA if the name differs
    IPA_PATH=$(find "$MOBILE_DIR/build/ios/ipa" -name "*.ipa" -print -quit 2>/dev/null)
    if [[ -z "$IPA_PATH" ]]; then
        echo "Error: IPA not found in build/ios/ipa/"
        exit 1
    fi
fi
echo "IPA built: $IPA_PATH"

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
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_PATH" \
        --apiKey "$ASC_API_KEY_ID" \
        --apiIssuer "$ASC_API_ISSUER_ID"
    echo "Upload complete!"
fi

echo ""
echo "Released $TAG"
