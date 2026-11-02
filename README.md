# ClipCopy

A native macOS menu bar utility for reusing copied text. Select a history entry, then paste with Cmd+V. Text history is encrypted locally with a key in macOS Keychain. No account, telemetry or cloud sync.

[Website](https://clipcopy.pages.dev/) · [English](https://clipcopy.pages.dev/en/) · [Download beta](https://github.com/MediaPublishing/clipcopy-app/releases/tag/v0.1.1)

## Beta requirements and setup

- Apple Silicon, macOS 15.4 or newer. Intel builds are not included.
- Download the release ZIP, extract it and move ClipCopy.app to Applications.
- Version 0.1.1 is Developer ID signed and Apple notarized, with the notarization ticket stapled to the app. macOS may still ask you to confirm opening a downloaded app and grant clipboard access.
- In Preferences… → General, enable **Record clipboard history**. Allow clipboard access if requested. If needed, choose persistent access in System Settings → Privacy & Security → Clipboard, then enable recording again. Only new copies are captured.
- Quit other clipboard apps before enabling recording. Launch at login is optional.

## Included and limits

Native text history menu, Cmd+1…9 while that menu is open, configurable storage/display count, excluded apps, pause, optional login start and encrypted SQLite persistence. Default: 1,000 entries. No time expiry; the count limit removes the oldest entries. Known password managers and confidential clipboard markers are excluded, but arbitrary sensitive text cannot be detected reliably.

No images/files, automatic paste, global hotkey, cloud sync, automatic updates or public history import. History depends on the local Keychain key; losing the key cannot be automatically repaired. Ad-hoc updates may require Keychain approval again. The secondary search view exists in the shared UI/demo but has no public global shortcut.

## Build and verify

Requires Swift 6.2+ and a current macOS SDK (Xcode or Command Line Tools):

```sh
scripts/build.sh
scripts/test.sh
python3 scripts/verify-public.py
open dist/ClipCopyDemo.app
```

The demo uses synthetic data and has no dependency on live clipboard access or archive storage. Tests use temporary encrypted fixtures and named pasteboards. Website files in `docs/` work without JavaScript. `python3 scripts/build-site.py` regenerates both language pages. Release ZIPs contain the app bundle only.

## Source and license

Clean public source baseline. Private development history, user data and operational reports are not included. Copyright © 2026 MediaPublishing. Publicly viewable source, with no usage license granted. Public visibility does not grant reuse rights. This project is not represented as open-source licensed.
