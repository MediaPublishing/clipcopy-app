#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
sdk="$(xcrun --sdk macosx --show-sdk-path)"
swift build --sdk "$sdk" --product ClipCopyTests
binary_path="$(swift build --sdk "$sdk" --show-bin-path)"
"$binary_path/ClipCopyTests"
