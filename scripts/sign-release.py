#!/usr/bin/env python3
"""Build, Developer-ID sign and notarize an app. Never creates credentials."""
from pathlib import Path
import hashlib
import json
import os
import plistlib
import re
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
os.chdir(root)
identity = os.environ.get('CLIPCOPY_SIGNING_IDENTITY', '')
profile = os.environ.get('CLIPCOPY_NOTARY_PROFILE', 'ClipCopy')
version = os.environ.get('CLIPCOPY_VERSION', '0.1.1')
if not identity or not re.fullmatch(r'\d+\.\d+\.\d+', version):
    sys.exit('Set CLIPCOPY_SIGNING_IDENTITY and a three-part CLIPCOPY_VERSION. No files changed.')

identities = subprocess.run(['security', 'find-identity', '-v', '-p', 'codesigning'],
                            capture_output=True, text=True, check=True).stdout
valid = re.findall(r'\b([A-F0-9]{40}) "(Developer ID Application: [^"]+)"', identities)
matched = [(fingerprint, name) for fingerprint, name in valid if identity in (fingerprint, name)]
if len(matched) != 1:
    sys.exit('The selected valid Developer ID Application identity is unavailable. No files changed.')

releases = root / 'releases'
final_zip = releases / f'ClipCopy-{version}-arm64.zip'
upload_zip = releases / f'ClipCopy-{version}-notarization.zip'
if final_zip.exists() or upload_zip.exists():
    sys.exit('This version already has a package. Choose a new version; existing releases are preserved.')

# Check the named profile before building/signing; no secret values are returned.
credential_check = subprocess.run(['xcrun', 'notarytool', 'history', '--keychain-profile', profile,
                                  '--output-format', 'json'], capture_output=True, text=True)
if credential_check.returncode:
    sys.exit('The named notarization profile is unavailable or unauthenticated. No files changed.')

env = dict(os.environ, CLIPCOPY_VERSION=version)
subprocess.run(['scripts/build.sh'], env=env, check=True)
app = root / 'dist/ClipCopy.app'
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert info['CFBundleShortVersionString'] == version
assert 'arm64' in subprocess.check_output(['file', str(app / 'Contents/MacOS/ClipCopy')], text=True)
subprocess.run(['codesign', '--force', '--options', 'runtime', '--timestamp', '--sign',
                matched[0][0], str(app)], check=True)
subprocess.run(['codesign', '--verify', '--strict', str(app)], check=True)
subprocess.run([str(app / 'Contents/MacOS/ClipCopy'), '--self-check'], check=True)
releases.mkdir(exist_ok=True)
subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(app), str(upload_zip)], check=True)
submission = subprocess.run(['xcrun', 'notarytool', 'submit', str(upload_zip), '--keychain-profile',
                             profile, '--wait', '--output-format', 'json'], capture_output=True, text=True)
if submission.returncode:
    sys.exit('Apple notarization failed. No final package or publication was produced.')
result = json.loads(submission.stdout)
if result.get('status') != 'Accepted':
    sys.exit('Apple did not accept the submission. No final package or publication was produced.')
subprocess.run(['xcrun', 'stapler', 'staple', str(app)], check=True)
subprocess.run(['xcrun', 'stapler', 'validate', str(app)], check=True)
subprocess.run(['codesign', '--verify', '--strict', str(app)], check=True)
subprocess.run(['spctl', '--assess', '--type', 'execute', '--verbose=2', str(app)], check=True)
subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(app), str(final_zip)], check=True)
digest = hashlib.sha256(final_zip.read_bytes()).hexdigest()
(releases / f'SHA256SUMS-{version}.txt').write_text(f'{digest}  {final_zip.name}\n')
(releases / f'notarization-{version}.json').write_text(json.dumps({
    'version': version, 'submissionID': result.get('id'), 'status': result['status'],
    'stapled': True, 'gatekeeperAccepted': True, 'sha256': digest
}, indent=2) + '\n')
print('Developer ID signature, Apple notarization, stapling and Gatekeeper assessment passed.')
print('Package ready under releases/. Nothing was uploaded to GitHub or a website.')
