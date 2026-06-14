# MiniDone Security Review

Last reviewed: 2026-06-14

## Scope

This review covers the local macOS app codebase, release build settings, app storage, drag-and-drop behavior, signing entitlements, and GitHub release packaging.

## Summary

MiniDone is a local-first macOS app. The reviewed codebase does not contain account login, cloud sync, backend calls, analytics, WebViews, keychain access, shell command execution, or hardcoded secrets.

The app stores task data locally through SwiftData and stores a small set of UI preferences in UserDefaults. Release builds are prepared to use the macOS App Sandbox and clean DMG/ZIP assets that contain only `MiniDone.app`.

## Stored Data

MiniDone stores:

- Tasks: title, completion state, creation/completion dates, due date, pinned/order state, recurrence, project, and tags.
- Projects: name, creation date, and color index.
- Tags: name and creation date.
- Preferences: language, theme, mini-window height, and onboarding completion state.

There is no deliberate export path in the app and no network code that sends this data elsewhere.

## Security-Relevant Checks

Checked surfaces:

- No `URLSession`, Network framework calls, WebKit/WebView usage, or cloud SDK usage.
- No shell/process execution APIs.
- No keychain or credential handling.
- No hardcoded API keys, tokens, passwords, signing certificates, provisioning profiles, or `.env` files.
- No logger/print paths that intentionally dump task content.
- Test seed/store hooks are compiled only in Debug builds.
- Release app packaging rejects `.xctest`, `.xcresult`, `.dSYM`, `DerivedData`, test-target names, `__MACOSX`, and `._` metadata files inside the final ZIP and DMG.
- Release signing verifies the App Sandbox entitlement and rejects the debug `get-task-allow` entitlement.
- Release packaging rejects UI-test environment hooks in the compiled binary.

## Improvements Applied

- Debug-only UI-test hooks are excluded from Release builds with `#if DEBUG`.
- Test-only store overrides now require `MINIDONE_UI_TESTS=1` and Debug compilation.
- Drag-and-drop no longer publishes task titles as plain text; it uses an internal opaque marker.
- Release builds use a minimal sandbox entitlement with no network or arbitrary file access.
- Release packaging creates a drag-to-Applications DMG and ZIP containing only `MiniDone.app` bundle contents.

## Residual Risks

- Task data is local and not app-level encrypted. A user or malware process with filesystem access to the user account may be able to read local SwiftData files.
- Public GitHub tags always expose GitHub-generated source archives. Users should download the attached `MiniDone-macOS-vX.Y.Z.dmg` installer asset, not the automatic source-code zip/tar archives.
- Public distribution still needs a real Apple Developer ID certificate and notarization for a smooth Gatekeeper experience.

## Release Checklist

- Run unit tests.
- Run UI tests.
- Run `scripts/package_release.sh`.
- Confirm the produced DMG and ZIP contain only `MiniDone.app`.
- Sign with Developer ID and notarize before broad public distribution.
