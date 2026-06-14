# Apple Trust Checklist

This checklist explains how to make MiniDone feel trusted on macOS when it is downloaded outside the Mac App Store.

## What "Trusted By Apple" Means

For GitHub distribution, a smooth first-open experience requires three pieces:

1. **Developer ID signing** with an Apple-issued Developer ID Application certificate.
2. **Apple notarization** of the signed app or disk image.
3. **Stapling** the notarization ticket to the distributed DMG.

Without those steps, MiniDone can still be built and shared, but macOS Gatekeeper may show a warning on first launch.

Official Apple references:

- [Developer ID - Signing Your Apps for Gatekeeper](https://developer.apple.com/developer-id/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Developer ID support](https://developer.apple.com/support/developer-id/)
- [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/)

## Requirements

- Apple Developer Program or Apple Developer Enterprise Program membership.
- Developer ID Application certificate installed in the macOS Keychain.
- Xcode command line tools available.
- Notary credentials saved in the Keychain with `notarytool`.

Check available signing identities:

```bash
security find-identity -p codesigning -v
```

The signing identity should look similar to:

```text
Developer ID Application: Your Name (TEAMID)
```

## One-Time Notary Credential Setup

Create an app-specific password for the Apple ID, then save notary credentials:

```bash
xcrun notarytool store-credentials minidone-notary \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

You can use a different keychain profile name by setting `MINIDONE_NOTARY_PROFILE`.

## Build A Developer ID Signed DMG

Run the release packaging script with your team and signing identity:

```bash
MINIDONE_DEVELOPMENT_TEAM="TEAMID" \
MINIDONE_CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  scripts/package_release.sh 1.0
```

This produces:

```text
dist/MiniDone-macOS-v1.0.dmg
dist/MiniDone-macOS-v1.0.zip
```

## Notarize And Staple

Submit the DMG to Apple, wait for the result, staple the ticket, and verify Gatekeeper:

```bash
scripts/notarize_release.sh 1.0
```

The script runs:

- `xcrun notarytool submit ... --wait`
- `xcrun stapler staple ...`
- `xcrun stapler validate ...`
- `spctl ...` Gatekeeper validation

If you used a custom notary profile:

```bash
MINIDONE_NOTARY_PROFILE="your-profile" scripts/notarize_release.sh 1.0
```

## Current Repository State

MiniDone is ready to package as a drag-to-Applications DMG. The project has Hardened Runtime enabled and a minimal App Sandbox entitlement.

The repository cannot complete Apple notarization by itself because Developer ID certificates and Apple notary credentials are private account assets. Once those credentials are available on the release machine, the scripts above can produce a signed, notarized, stapled DMG.
