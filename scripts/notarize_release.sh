#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/MiniDone.xcodeproj"
SCHEME="MiniDone"
CONFIGURATION="Release"
DESTINATION="${MINIDONE_RELEASE_DESTINATION:-generic/platform=macOS}"
PROFILE="${MINIDONE_NOTARY_PROFILE:-minidone-notary}"

if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(
    xcodebuild -showBuildSettings \
      -project "$PROJECT_PATH" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" 2>/dev/null |
      awk -F'= ' '/MARKETING_VERSION/ { print $2; exit }'
  )"
fi

if [[ -z "$VERSION" ]]; then
  echo "Could not resolve MiniDone version." >&2
  exit 1
fi

DMG_PATH="$ROOT_DIR/dist/MiniDone-macOS-v$VERSION.dmg"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Release DMG was not found at $DMG_PATH" >&2
  echo "Run scripts/package_release.sh $VERSION first." >&2
  exit 1
fi

echo "Submitting $DMG_PATH to Apple notarization with keychain profile '$PROFILE'..."
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$PROFILE" --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Checking Gatekeeper acceptance..."
spctl -a -vv -t open --context context:primary-signature "$DMG_PATH"

echo "Notarized and stapled $DMG_PATH"
