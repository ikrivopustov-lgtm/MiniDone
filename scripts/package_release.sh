#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/MiniDone.xcodeproj"
SCHEME="MiniDone"
CONFIGURATION="Release"
DESTINATION="${MINIDONE_RELEASE_DESTINATION:-generic/platform=macOS}"
DIST_DIR="$ROOT_DIR/dist"
DEFAULT_DERIVED_DATA_DIR=""
if [[ -n "${MINIDONE_RELEASE_DERIVED_DATA_DIR:-}" ]]; then
  DERIVED_DATA_DIR="$MINIDONE_RELEASE_DERIVED_DATA_DIR"
else
  DEFAULT_DERIVED_DATA_DIR="$(mktemp -d "${TMPDIR:-/tmp}/MiniDoneRelease.XXXXXX")"
  DERIVED_DATA_DIR="$DEFAULT_DERIVED_DATA_DIR"
fi

cd "$ROOT_DIR"
export COPYFILE_DISABLE=1

cleanup() {
  if [[ -n "$DEFAULT_DERIVED_DATA_DIR" && "$DERIVED_DATA_DIR" == "$DEFAULT_DERIVED_DATA_DIR" ]]; then
    rm -rf "$DEFAULT_DERIVED_DATA_DIR"
  fi
}
trap cleanup EXIT

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

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/MiniDone.app"
ZIP_PATH="$DIST_DIR/MiniDone-macOS-v$VERSION.zip"
ENTITLEMENTS_CHECK_PATH="$DERIVED_DATA_DIR/MiniDone.entitlements.actual.plist"

rm -rf "$DERIVED_DATA_DIR" "$ZIP_PATH" "$ENTITLEMENTS_CHECK_PATH"
mkdir -p "$DIST_DIR"

xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_DIR"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Release app was not produced at $APP_PATH" >&2
  exit 1
fi

APP_ARCHS="$(lipo -archs "$APP_PATH/Contents/MacOS/MiniDone")"
if [[ "$APP_ARCHS" != *"arm64"* || "$APP_ARCHS" != *"x86_64"* ]]; then
  echo "Release binary must be universal for arm64 and x86_64. Found: $APP_ARCHS" >&2
  exit 1
fi

if find "$APP_PATH" \( -name "*.xctest" -o -name "*.xcresult" -o -name "*.dSYM" \) -print -quit | grep -q .; then
  echo "Release app contains test or debug artifacts." >&2
  exit 1
fi

xattr -cr "$APP_PATH" 2>/dev/null || true
codesign --verify --deep --strict "$APP_PATH"
codesign -d --entitlements :- "$APP_PATH" > "$ENTITLEMENTS_CHECK_PATH" 2>/dev/null

if ! /usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" "$ENTITLEMENTS_CHECK_PATH" 2>/dev/null | grep -q "true"; then
  echo "Release app is not sandboxed." >&2
  exit 1
fi

if /usr/libexec/PlistBuddy -c "Print :com.apple.security.get-task-allow" "$ENTITLEMENTS_CHECK_PATH" 2>/dev/null | grep -q "true"; then
  echo "Release app contains debug entitlement get-task-allow." >&2
  exit 1
fi

if strings "$APP_PATH/Contents/MacOS/MiniDone" | grep -E "MINIDONE_(UI_TESTS|STORE_URL|RESET_STORE|SEED_SCENARIO)" >/dev/null; then
  echo "Release binary contains UI-test environment hooks." >&2
  exit 1
fi

ditto -c -k --norsrc --noextattr --keepParent "$APP_PATH" "$ZIP_PATH"

if unzip -l "$ZIP_PATH" | grep -E "(\.xctest|\.xcresult|\.dSYM|DerivedData|MiniDoneTests|MiniDoneUITests|__MACOSX|/\._)" >/dev/null; then
  echo "Release zip contains development artifacts." >&2
  exit 1
fi

echo "Created $ZIP_PATH"
