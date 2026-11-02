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
