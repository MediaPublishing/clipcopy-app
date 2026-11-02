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

## Initial public readback (November 1, historical)

- Source/release commit: `38a72a8437b5ab9c1b35ddacb6c4969795ad1a38`. Public repository: https://github.com/MediaPublishing/clipcopy-app. The separate original development repository remains private.
- Both macOS Checks runs succeeded on the source/release commit, including native build/signature verification, 24 synthetic tests and the static source/HTML guard: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41373242675.
- GitHub Pages deployment succeeded: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41373277262. Live https://mediapublishing.github.io/clipcopy-app/ and /en/ matched local HTML bytes. CSS, four displayed screenshots, ICO, PNG favicon and Apple touch icon all returned HTTP 200 with expected content types and bytes.
- All 12 no-JavaScript browser cases also passed against the public site.
- Public prerelease: https://github.com/MediaPublishing/clipcopy-app/releases/tag/v0.1.0. The ZIP was downloaded without authentication and matched the packaged asset exactly: SHA-256 `0e8653f0b87f0a854a7cfdf4fbc278805b1a03d70eb6376d6e9b346e6071397c`, 214831 bytes.

## Cloudflare update (November 2)

The primary website is now https://clipcopy.pages.dev/ and https://clipcopy.pages.dev/en/. It was deployed through the existing Cloudflare dashboard session as a static Pages direct upload. No new Wrangler authorization was granted. The generated default canonical URL, repository homepage and README now point to Cloudflare; page-relative assets keep the former GitHub Pages address usable with the Cloudflare canonical.

Current public page/product text no longer mentions the previous reference product or vendor. Both Cloudflare HTML responses and the favicon matched local files byte-for-byte. All 12 live browser cases passed in German/English, light/dark, at 390/900/1440 pixels, without JavaScript, overflow or missing images; keyboard FAQ checks also passed. The previous GitHub Pages address was checked and also serves the cleaned text.

The reviewed preparation commit is `b62d191bcfbec86f8bdaa2af90eff66880d3dc54`; its GitHub Checks run passed: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41494728118. Local native build and all 24 synthetic tests passed. The signing helper was tested with absent/invalid identity configuration and stopped without changing existing release artifacts.

Developer ID signing and Apple notarization remain pending the required signing identity and notarization access. No new signed artifact has been published; v0.1.0 and its checksum remain unchanged. See SIGNING.md for the prepared fail-closed workflow.

## Developer ID release 0.1.1 (November 2)

- App and test source are unchanged from the successful baseline CI run: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41495549446. That run includes the 24 synthetic tests. The new local native release build passed. A local full-suite rerun could not write a named test pasteboard in restricted execution; elevated execution was rejected by automatic review and was not bypassed. No new local full-suite success is claimed.
- Version 0.1.1 was signed with the existing Developer ID Application identity for Reto Stuber Global Headquarters LLC, team F7ZC4PZ39V, hardened runtime and a secure timestamp. The signed executable passed its synthetic self-check without archive or Keychain access.
- Apple accepted submission `a6c71b78-baeb-423b-9e6e-56223076afb3`. The ticket was stapled before final ZIP creation. A separate copy extracted from the final ZIP passed strict codesign verification, stapler validation and Gatekeeper assessment (`source=Notarized Developer ID`). The app was not normally launched or installed during verification.
- The ZIP contains only the app bundle and macOS archive metadata. No user archives, credentials, private resources or logs are included. Size: 221910 bytes. SHA-256: `661c8722d5c51e72a9c43805ec26768885b914184b94b9587e0f40967cecd0a2`.
- German and English download links and installation text now target 0.1.1. Static HTML/source guards and the staged secret scan passed. No layout, feature, dependency or license change was introduced. The v0.1.0 package is preserved byte-for-byte as a rollback download.

### Published 0.1.1 readback

Release source/documentation commit: `d5f192d76c25de285183da2a4830a8a8b3581039`. Checks passed: https://github.com/MediaPublishing/clipcopy-app/actions/runs/41527233412. Public prerelease: https://github.com/MediaPublishing/clipcopy-app/releases/tag/v0.1.1.

Cloudflare production deployment `379c6cec` succeeded with 12 allowlisted static files. Both https://clipcopy.pages.dev/ and https://clipcopy.pages.dev/en/ matched the generated HTML bytes and link to the signed 0.1.1 ZIP. The anonymous GitHub download matched SHA-256 `661c8722d5c51e72a9c43805ec26768885b914184b94b9587e0f40967cecd0a2` exactly (221910 bytes). Its extracted app independently passed strict signature verification, ticket validation and Gatekeeper (`Notarized Developer ID`). The installed app, clipboard and existing history were not accessed or replaced.
