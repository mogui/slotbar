#!/bin/bash
# Build the universal release app for tag vX.Y.Z and publish it as a GitHub Release (SPEC 12.4).
set -euo pipefail

tag="${1:?usage: $0 vX.Y.Z}"
case "$tag" in
  v*) ;;
  *) echo "release tag must start with v: $tag" >&2; exit 2 ;;
esac
version="${tag#v}"

cd "$(dirname "$0")/.."

VERSION="$version" BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-0}}" scripts/build-app.sh release

zip="build/Slotbar-$version.zip"
rm -f "$zip"
ditto -c -k --keepParent build/Slotbar.app "$zip"
hash="$(shasum -a 256 "$zip" | cut -d' ' -f1)"
echo "SHA-256: $hash"

gh release create "$tag" "$zip" --notes "SHA-256: $hash" --generate-notes
