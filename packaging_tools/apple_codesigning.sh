#!/bin/bash
# helper script for GitHub action

set -ex
if (( $# < 3 )); then
  echo "usage: $0 source.tgz version_str final.dmg"
  exit 1
fi

SRCTAR="$1"
version="$2"
FINAL_DMG="$3"

if [ ! -f "$SRCTAR" ]; then
  echo "Source tar $SRCTAR not found!"
  exit 1
fi
tar xf ${SRCTAR}
BASENAME=$(basename $SRCTAR)
BDP_SOURCE_FOLDER=${BASENAME%.tar.gz}
if [ ! -d "$BDP_SOURCE_FOLDER" ]; then
  echo "Source folder not found $BDP_SOURCE_FOLDER!"
  ls -l
  exit 1
fi

echo ">>> [Pre-Pass Step 1/3] Recursively re-signing all background math modules..."
find "$BDP_SOURCE_FOLDER" -type f \( -perm +111 -o -name "*.dylib" -o -name "*.so" -o -name "*.sh" -o -name "*.mexmaci64" \) ! -name "prelaunch" | while read -r binary; do
    codesign --remove-signature "$binary" 2>/dev/null || true
    codesign --force --options runtime --no-strict --sign "$MACOS_DEVELOPER_ID" --timestamp "$binary" 2>/dev/null || true
done

echo ">>> [Pre-Pass Step 2/3] Sealing primary executable engines..."
MAIN_EXECS=(
    "$BDP_SOURCE_FOLDER/bdp.app/Contents/MacOS/applauncher"
    "$BDP_SOURCE_FOLDER/bdp.app/Contents/MacOS/BrainSuite_Diffusion_pipeline"
)
for exec in "${MAIN_EXECS[@]}"; do
    if [ -f "$exec" ]; then
        codesign --remove-signature "$exec" 2>/dev/null || true
        codesign --force --options runtime --no-strict --sign "$MACOS_DEVELOPER_ID" --timestamp "$exec" 2>/dev/null || true
    fi
done

echo ">>> [Pre-Pass Step 3/3] Finalizing MATLAB prelaunch runtime wrapper..."
PRELAUNCH_PATH="$BDP_SOURCE_FOLDER/bdp.app/Contents/MacOS/prelaunch"
if [ -f "$PRELAUNCH_PATH" ]; then
    codesign --remove-signature "$PRELAUNCH_PATH" 2>/dev/null || true
    codesign --force --options runtime --no-strict --sign "$MACOS_DEVELOPER_ID" --timestamp "$PRELAUNCH_PATH" 2>/dev/null || true
fi

TMP_DMG="./raw_${version}_bdp.dmg"
rm -f "$TMP_DMG" "$FINAL_DMG"

echo ">>> [1/3] Packaging Compressed DMG..."
hdiutil create -srcfolder "$BDP_SOURCE_FOLDER" \
                -volname "bdp${version}" \
                -fs HFS+ \
                -fsargs "-c c=64,a=16,e=16" \
                -format UDRW "$TMP_DMG"

hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"
rm -f "$TMP_DMG"

echo ">>> [2/3] Signing Outer DMG Container..."
codesign --force --sign "$MACOS_DEVELOPER_ID" --timestamp "$FINAL_DMG"

echo ">>> [3/3] Submitting to Apple Notarization Server..."

if xcrun notarytool submit "$FINAL_DMG" \
  --apple-id "$MACOS_NOTARIZATION_APPLE_ID" --password "$MACOS_NOTARIZATION_PWD" --team-id "$MACOS_TEAM_ID" \
  --wait; then
    echo "Stapling notarization ticket directly to file structure..."
    xcrun stapler staple "$FINAL_DMG"
    echo ">>> SUCCESS: Staged and Notarized at $FINAL_DMG"
else
    echo ">>> ERROR: Apple rejected the notarization payload for BDP $version."
fi

# Clean working space tracks
rm -rf "$BDP_SOURCE_FOLDER"
