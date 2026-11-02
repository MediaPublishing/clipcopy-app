#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
file dist/ClipCopy.app/Contents/MacOS/ClipCopy | grep 'arm64'
codesign --verify --strict dist/ClipCopy.app
mkdir -p releases
ditto -c -k --sequesterRsrc --keepParent dist/ClipCopy.app releases/ClipCopy-0.1.0-arm64.zip
(cd releases && shasum -a 256 ClipCopy-0.1.0-arm64.zip > SHA256SUMS.txt)
