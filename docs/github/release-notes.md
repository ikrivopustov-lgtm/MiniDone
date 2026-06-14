# MiniDone v1.0

MiniDone is a quiet native macOS task manager for quick capture, focused work, and clean recovery.

## Download

Download [MiniDone-macOS-v1.0.dmg](https://github.com/ikrivopustov-lgtm/MiniDone/releases/download/v1.0/MiniDone-macOS-v1.0.dmg), open the DMG, and drag `MiniDone.app` to Applications.

ZIP fallback: [MiniDone-macOS-v1.0.zip](https://github.com/ikrivopustov-lgtm/MiniDone/releases/download/v1.0/MiniDone-macOS-v1.0.zip).

GitHub also shows automatic **Source code** downloads. Those are for developers and include the repository files and tests. For normal installation, use the `MiniDone-macOS-v1.0.dmg` installer asset.

## Supported Macs

- macOS 14 or newer
- Apple Silicon Macs
- Intel Macs

## Highlights

- Fast one-line task entry.
- Smart commands for tags, projects, dates, and recurring tasks.
- Projects, tags, Today, Completed, pinned tasks, search, and drag reordering.
- Menu bar mini window for quick capture and completion.
- Restore or permanently delete completed tasks.
- Russian and English UI.
- System, light, and dark themes.
- Local-first SwiftData storage.
- First-run onboarding for the main workflows.

## Fixes

- First-run onboarding now appears reliably for the current v1 walkthrough, even if an earlier local build had already saved the old onboarding flag.

## Privacy

MiniDone has no account login, analytics, cloud backend, WebView, or network sync in this codebase. Task data is stored locally on your Mac.

## Release Integrity

The release assets are built from the Release configuration and packaged as a clean DMG installer plus ZIP archive. The packaging script rejects test bundles, debug artifacts, UI-test launch hooks, debug entitlements, `DerivedData`, `dSYM`, `xcresult`, `__MACOSX`, and macOS `._` metadata files.

## Note About macOS Gatekeeper

This build is prepared for GitHub distribution. A fully public production distribution should still use Developer ID signing and notarization for the smoothest first-open experience.
