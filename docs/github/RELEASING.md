# Releasing MiniDone

This checklist is for maintainers publishing a MiniDone GitHub Release.

## Before A Release

1. Update `MARKETING_VERSION` in the Xcode project if the version changes.
2. Update `docs/github/release-notes.md`.
3. Run unit tests.
4. Run UI tests.
5. Run the release package script:

```bash
scripts/package_release.sh
```

6. Confirm the release assets exist at:

```text
dist/MiniDone-macOS-vX.Y.Z.dmg
dist/MiniDone-macOS-vX.Y.Z.zip
```

## Publish Through GitHub Actions

Create and push a version tag:

```bash
git tag v1.0
git push origin v1.0
```

The release workflow builds the app, creates a clean `MiniDone-macOS-vX.Y.Z.dmg` installer plus `MiniDone-macOS-vX.Y.Z.zip`, and attaches both to a GitHub Release.

## Manual Fallback

If the workflow is unavailable, upload the locally generated `dist/MiniDone-macOS-vX.Y.Z.dmg` and `dist/MiniDone-macOS-vX.Y.Z.zip` files to a GitHub Release manually.

Use the release notes from:

```text
docs/github/release-notes.md
```

## Public Distribution

For a smoother first-open experience outside local development, use Apple Developer ID signing and notarization before distributing broadly. See [`APPLE_TRUST.md`](APPLE_TRUST.md).
