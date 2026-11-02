#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
configuration="${1:-release}"
sdk="$(xcrun --sdk macosx --show-sdk-path)"
for product in ClipCopy ClipCopyDemo ClipCopyChecks ClipCopyTests; do
  swift build --sdk "$sdk" -c "$configuration" --product "$product"
done
binary_path="$(swift build --sdk "$sdk" -c "$configuration" --show-bin-path)"
python3 - "$binary_path" <<'PY'
from pathlib import Path
import sys, plistlib, shutil, subprocess, os, tempfile, re
version=os.environ.get('CLIPCOPY_VERSION','0.1.0')
if not re.fullmatch(r'\d+\.\d+\.\d+',version):
    raise SystemExit('CLIPCOPY_VERSION must be a three-part numeric version.')
for product,identifier in [('ClipCopy','com.mediapublishing.ClipCopy'),('ClipCopyDemo','com.mediapublishing.ClipCopyDemo')]:
    app=Path('dist')/(product+'.app')
    mac=app/'Contents/MacOS'; mac.mkdir(parents=True,exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=mac,prefix=product+'.',delete=False) as staged:
        staged_path=Path(staged.name)
    shutil.copy2(Path(sys.argv[1])/product,staged_path)
    os.replace(staged_path,mac/product)
    info={'CFBundleName':product,'CFBundleDisplayName':product,'CFBundleIdentifier':identifier,'CFBundleExecutable':product,'CFBundlePackageType':'APPL','CFBundleShortVersionString':version,'CFBundleVersion':version,'LSMinimumSystemVersion':'15.4','LSUIElement':True,'NSHighResolutionCapable':True}
    (app/'Contents/Info.plist').write_bytes(plistlib.dumps(info))
    subprocess.run(['codesign','--force','--sign','-','--options','runtime',str(app)],check=True)
    subprocess.run(['codesign','--verify','--strict',str(app)],check=True)
print('App bundles built and ad-hoc signed under dist/. No Apple notarization.')
PY
