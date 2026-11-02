# Developer ID release preparation

Version 0.1.1 is Developer ID signed and Apple notarized. Its ticket is stapled to the app. Strict signature verification, ticket validation and Gatekeeper assessment passed on a copy extracted from the final ZIP. Version 0.1.0 remains available as the historical ad-hoc signed, non-notarized prerelease.

Prerequisites on the signing Mac:

1. A valid **Developer ID Application** certificate with its private key in the local Keychain. An Apple Development, Mac Distribution or local self-signed certificate is not equivalent.
2. An authenticated `notarytool` Keychain profile named `ClipCopy`, or another explicitly named existing profile. Prepare credentials through Apple's secure interactive setup. Do not place passwords, API keys, private keys or certificate exports in Git or command arguments.
3. Existing Apple Developer Program membership and authorized access to the chosen team. Account sign-in, MFA and certificate setup may require the account holder.

Run `python3 scripts/sign-release.py` with the public certificate name/fingerprint in `CLIPCOPY_SIGNING_IDENTITY`, a new version in `CLIPCOPY_VERSION` (default 0.1.1), and optionally the profile name in `CLIPCOPY_NOTARY_PROFILE`.

The helper checks the existing identity and credentials before changing files. It builds the app, signs with hardened runtime and secure timestamp, submits the app to Apple, requires an Accepted result, staples/validates the ticket, assesses Gatekeeper and creates a new versioned ZIP/checksum. It never creates credentials, changes the installed app, publishes a release, or overwrites an existing package. CI continues to build an explicitly ad-hoc test bundle without signing credentials.

Apple reference: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
