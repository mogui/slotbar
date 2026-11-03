#!/bin/bash
# Build the universal release app for tag vX.Y.Z, package it as a DMG and publish it as a GitHub Release (SPEC 12.4).
# Without GH_TOKEN/gh auth, run with PUBLISH=0 to stop after building the DMG.
set -euo pipefail

tag="${1:?usage: $0 vX.Y.Z}"
case "$tag" in
  v*) ;;
  *) echo "release tag must start with v: $tag" >&2; exit 2 ;;
esac
version="${tag#v}"

cd "$(dirname "$0")/.."

VERSION="$version" BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-0}}" scripts/build-app.sh release

# DMG window content: the app next to an Applications link to drag it onto.
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
ditto build/Slotbar.app "$staging/Slotbar.app"
ln -s /Applications "$staging/Applications"

dmg="build/Slotbar-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "Slotbar $version" -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$dmg"
hash="$(shasum -a 256 "$dmg" | cut -d' ' -f1)"
echo "Built $dmg"
echo "SHA-256: $hash"

[ "${PUBLISH:-1}" = 1 ] || exit 0

notes="$(cat <<EOF
## Install

1. Open \`Slotbar-$version.dmg\` and drag Slotbar to Applications.
2. The app is not notarized: remove the quarantine flag, then open it.
   \`\`\`sh
   xattr -dr com.apple.quarantine /Applications/Slotbar.app
   open /Applications/Slotbar.app
   \`\`\`

SHA-256 (\`Slotbar-$version.dmg\`): \`$hash\`
EOF
)"
gh release create "$tag" "$dmg" --title "Slotbar $version" --notes "$notes" --generate-notes
