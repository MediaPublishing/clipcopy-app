# Release verification

Clean public baseline, version 0.1.0. Source is publicly viewable without a usage license; it is not advertised as open-source licensed.

- Portable macOS SDK build completed for the app, synthetic demo, checks and tests. Strict ad-hoc signature verification passed. Apple Silicon arm64, minimum macOS 15.4. No Developer ID or notarization claim.
- 24 synthetic tests passed. The private migration feature and its two tests are excluded together; encrypted storage, corruption/wrong-key protection, capture filtering and native UI tests remain.
- The actual release executable passed `--self-check`, which exits before live controller/archive/keychain setup and exercises a synthetic native menu. A temporary-HOME invocation wrote no archive. This is not an end-to-end first-install permission or Gatekeeper test.
- Static public-source/HTML guard passed. Demo dependency closure excludes native clipboard/storage modules. Staged source secret scan passed with no findings. The guard is not a binary scanner.
- Release ZIP inspected separately: only app-bundle metadata, executable and signature resources; no archive, private migration, credentials, logs, user data or vendor resources. SHA256SUMS.txt accompanies the asset. Strict signature check passed after packaging.
- Static German and English pages tested with JavaScript disabled at 390, 900 and 1440 pixels, in light and dark themes (12 cases). All images loaded, no horizontal overflow, correct language/canonical metadata, and FAQ opened/closed with the keyboard. Desktop light and mobile dark screenshots visually reviewed. Skip-link visibility and desktop headline wrapping were corrected and all captures regenerated.
- Independent read-only review found no material code regression. Its two evidence issues (stale screenshots and overly broad static-guard scope) were corrected and rechecked. Live deployment and remote-download results are recorded after publication.

Known limits: manual macOS approval can be required for clipboard access, ad-hoc launch and Keychain trust; these approvals were not bypassed. No normal first-run permission flow was exercised against a fresh personal account. Website contains no tracking scripts, third-party fonts or JavaScript.

## Public readback

- Source/release commit: `38a72a8437b5ab9c1b35ddacb6c4969795ad1a38`. Public repository: https://github.com/MediaPublishing/clipcopy-app. The separate original development repository remains private.
- Both macOS Checks runs succeeded on the source/release commit, including native build/signature verification, 24 synthetic tests and the static source/HTML guard: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41373242675.
- GitHub Pages deployment succeeded: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41373277262. Live https://mediapublishing.github.io/clipcopy-app/ and /en/ matched local HTML bytes. CSS, four displayed screenshots, ICO, PNG favicon and Apple touch icon all returned HTTP 200 with expected content types and bytes.
- All 12 no-JavaScript browser cases also passed against the public site.
- Public prerelease: https://github.com/MediaPublishing/clipcopy-app/releases/tag/v0.1.0. The ZIP was downloaded without authentication and matched the packaged asset exactly: SHA-256 `0e8653f0b87f0a854a7cfdf4fbc278805b1a03d70eb6376d6e9b346e6071397c`, 214831 bytes.

## Session finish

The original clipboard app had more than one login-start mechanism. The concrete extra entry was visible in macOS Login Items, separately from its own preference. Operational changes and metadata-only synthetic-copy evidence remain in the private project, not this public history. No global permission/security changes or user-history imports were performed. The useful release improvement is the existing static-source guard plus explicit separate artifact inspection; no new service, monitoring job or global policy was added.
