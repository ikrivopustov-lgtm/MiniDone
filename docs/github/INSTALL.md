# Install MiniDone From GitHub

MiniDone is distributed through GitHub Releases as a macOS DMG installer.

## Download

Latest version: [Download MiniDone v1.0 DMG installer](https://github.com/ikrivopustov-lgtm/MiniDone/releases/download/v1.0/MiniDone-macOS-v1.0.dmg)

| Version | Platform | DMG installer | ZIP archive | Release notes |
| --- | --- | --- | --- | --- |
| v1.0 | macOS 14+, Apple Silicon + Intel | [MiniDone-macOS-v1.0.dmg](https://github.com/ikrivopustov-lgtm/MiniDone/releases/download/v1.0/MiniDone-macOS-v1.0.dmg) | [MiniDone-macOS-v1.0.zip](https://github.com/ikrivopustov-lgtm/MiniDone/releases/download/v1.0/MiniDone-macOS-v1.0.zip) | [View release](https://github.com/ikrivopustov-lgtm/MiniDone/releases/tag/v1.0) |

For older builds, open the [GitHub Releases page](https://github.com/ikrivopustov-lgtm/MiniDone/releases).

Do not download GitHub's automatic **Source code** archives unless you want the developer project.

## Install With The DMG

1. Download `MiniDone-macOS-vX.Y.Z.dmg`.
2. Open the DMG file.
3. Drag `MiniDone.app` to the Applications shortcut.
4. Eject the MiniDone disk image.
5. Open MiniDone from Applications.

## ZIP Fallback

If the DMG is unavailable, download `MiniDone-macOS-vX.Y.Z.zip`, unzip it, move `MiniDone.app` to Applications, and open it.

## If macOS Shows a Warning

Early GitHub builds may not be notarized yet. If macOS says the app cannot be opened because it was downloaded from the internet:

1. Control-click or right-click `MiniDone.app`.
2. Choose **Open**.
3. Confirm **Open** once.

After that, macOS should remember the choice for this app.

For fully trusted public distribution, MiniDone needs Developer ID signing and Apple notarization. The maintainer checklist is in [`APPLE_TRUST.md`](APPLE_TRUST.md).

## Supported Platforms

| Platform | Support |
| --- | --- |
| macOS 14+ Apple Silicon | Yes |
| macOS 14+ Intel | Yes |
| Windows | No |
| Linux | No |
| iOS / iPadOS | No |
| Web | No |

## Privacy

MiniDone stores tasks, projects, tags, and preferences locally on your Mac. It has no account login, analytics, cloud backend, or WebView in this codebase.
