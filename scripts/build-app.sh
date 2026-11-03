#!/bin/bash
# Build build/Slotbar.app from the SwiftPM package and ad-hoc sign it (SPEC 12.2).
set -euo pipefail

config="${1:-debug}"
case "$config" in
  debug) build_args=(-c debug) ;;
  release) build_args=(-c release --arch arm64 --arch x86_64) ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."

swift build "${build_args[@]}"
bin_dir="$(swift build "${build_args[@]}" --show-bin-path)"

app="build/Slotbar.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Slotbar" "$app/Contents/MacOS/Slotbar"
find Resources -maxdepth 1 -type f ! -name Info.plist -exec cp {} "$app/Contents/Resources/" \;

sed -e "s/__VERSION__/${VERSION:-0.0.0-dev}/" -e "s/__BUILD_NUMBER__/${BUILD_NUMBER:-0}/" \
  Resources/Info.plist > "$app/Contents/Info.plist"

codesign --force --deep -s - "$app"
codesign --verify --strict "$app"
echo "Built $app ($config)"
