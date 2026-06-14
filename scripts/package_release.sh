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
if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

DMG_ATTACHED=0

detach_dmg() {
  if [[ "$DMG_ATTACHED" == "1" && -n "${DMG_MOUNT_DIR:-}" ]]; then
    hdiutil detach "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
    DMG_ATTACHED=0
  fi
}

cleanup() {
  detach_dmg
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
DMG_PATH="$DIST_DIR/MiniDone-macOS-v$VERSION.dmg"
ENTITLEMENTS_CHECK_PATH="$DERIVED_DATA_DIR/MiniDone.entitlements.actual.plist"
DMG_STAGING_DIR="$DERIVED_DATA_DIR/dmg-staging"
DMG_MOUNT_DIR="$DERIVED_DATA_DIR/dmg-mount"
DMG_VOLUME_NAME="MiniDone $VERSION"
XCODEBUILD_SIGNING_ARGS=()

if [[ -n "${MINIDONE_DEVELOPMENT_TEAM:-}" ]]; then
  XCODEBUILD_SIGNING_ARGS+=(DEVELOPMENT_TEAM="$MINIDONE_DEVELOPMENT_TEAM")
fi

if [[ -n "${MINIDONE_CODE_SIGN_IDENTITY:-}" ]]; then
  XCODEBUILD_SIGNING_ARGS+=(
    CODE_SIGN_IDENTITY="$MINIDONE_CODE_SIGN_IDENTITY"
    CODE_SIGN_STYLE=Manual
    OTHER_CODE_SIGN_FLAGS="--timestamp"
  )
fi

rm -rf "$DERIVED_DATA_DIR" "$ZIP_PATH" "$DMG_PATH" "$ENTITLEMENTS_CHECK_PATH"
mkdir -p "$DIST_DIR"

XCODEBUILD_ARGS=(
  build
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_DIR"
)

if [[ ${#XCODEBUILD_SIGNING_ARGS[@]} -gt 0 ]]; then
  XCODEBUILD_ARGS+=("${XCODEBUILD_SIGNING_ARGS[@]}")
fi

xcodebuild "${XCODEBUILD_ARGS[@]}"

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

rm -rf "$DMG_STAGING_DIR" "$DMG_MOUNT_DIR"
mkdir -p "$DMG_STAGING_DIR" "$DMG_MOUNT_DIR"
ditto --norsrc --noextattr "$APP_PATH" "$DMG_STAGING_DIR/MiniDone.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create \
  -volname "$DMG_VOLUME_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -format UDZO \
  -fs HFS+ \
  -ov \
  "$DMG_PATH" >/dev/null

hdiutil verify "$DMG_PATH" >/dev/null
hdiutil attach "$DMG_PATH" -readonly -nobrowse -mountpoint "$DMG_MOUNT_DIR" >/dev/null
DMG_ATTACHED=1

if [[ ! -d "$DMG_MOUNT_DIR/MiniDone.app" ]]; then
  echo "Release DMG does not contain MiniDone.app." >&2
  exit 1
fi

if [[ ! -L "$DMG_MOUNT_DIR/Applications" || "$(readlink "$DMG_MOUNT_DIR/Applications")" != "/Applications" ]]; then
  echo "Release DMG does not contain an Applications shortcut." >&2
  exit 1
fi

codesign --verify --deep --strict "$DMG_MOUNT_DIR/MiniDone.app"

if find "$DMG_MOUNT_DIR" \( -name "*.xctest" -o -name "*.xcresult" -o -name "*.dSYM" -o -name "DerivedData" -o -name "MiniDoneTests" -o -name "MiniDoneUITests" -o -name "__MACOSX" -o -name "._*" \) -print -quit | grep -q .; then
  echo "Release DMG contains development artifacts." >&2
  exit 1
fi

detach_dmg

echo "Created $ZIP_PATH"
echo "Created $DMG_PATH"
