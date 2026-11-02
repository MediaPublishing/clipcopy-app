# Local data and privacy

ClipCopy has no account, analytics, telemetry or background network requests. History is stored as encrypted SQLite records in `~/Library/Application Support/ClipCopy/history.sqlite`; the local nonsynchronizing macOS Keychain contains the encryption key. The archive is excluded from normal backups. Key loss can therefore make history unrecoverable. Updating an ad-hoc signed build can require another Keychain approval.

The default count limit is 1,000; the oldest entries are removed when it is exceeded. There is no time-based expiry. Reducing a limit and clearing/deleting history are explicit local actions. Sensitive markers and known password managers are filtered, but arbitrary sensitive text cannot be reliably detected. Pause recording or exclude apps when needed. No Accessibility or Screen Recording permission is used for recording or pasting. Pasting is always performed by the user.

This website is static and loads no tracking scripts or external fonts. Hosting and release downloads are provided by GitHub; GitHub handles its own server/access logs. Clicking an external link opens that provider. ClipCopy is not affiliated with FIPLAB or CopyClip.
