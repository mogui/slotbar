#!/bin/bash
# Build build/Slotbar.app from the SwiftPM package and ad-hoc sign it (SPEC 12.2).
set -euo pipefail

config="${1:-debug}"
case "$config" in
  debug) archs=() ;;
  # One `swift build` per arch, joined with lipo: a multi-arch `swift build` switches to the Xcode build
  # system, which fails with Swift 6 on some runner images.
  release) archs=(arm64 x86_64) ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."

# Swift Build's resource accessor finds dependency bundles in Contents/Resources. The native build system
# (the default before Swift 6.4) looks next to Slotbar.app instead, so KeyboardShortcuts crashes in Settings.
build=(swift build --build-system swiftbuild)

app="build/Slotbar.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

if [ ${#archs[@]} -eq 0 ]; then
  "${build[@]}" -c debug
  bin_dir="$("${build[@]}" -c debug --show-bin-path)"
  cp "$bin_dir/Slotbar" "$app/Contents/MacOS/Slotbar"
else
  # Copied out per arch: some toolchains build every arch into the same bin path.
  slices="$(mktemp -d)"
  for arch in "${archs[@]}"; do
    "${build[@]}" -c release --arch "$arch"
    bin_dir="$("${build[@]}" -c release --arch "$arch" --show-bin-path)"
    cp "$bin_dir/Slotbar" "$slices/Slotbar-$arch"
  done
  lipo -create "$slices"/Slotbar-* -output "$app/Contents/MacOS/Slotbar"
  rm -rf "$slices"
fi
find Resources -maxdepth 1 -type f ! -name Info.plist -exec cp {} "$app/Contents/Resources/" \;
# SwiftPM resource bundles of dependencies (KeyboardShortcuts), looked up via Bundle.main.resourceURL.
find "$bin_dir" -maxdepth 1 -name "*.bundle" -exec cp -R {} "$app/Contents/Resources/" \;
# The native accessor embeds the absolute build path of each bundle.
if strings -a "$app/Contents/MacOS/Slotbar" | grep -q "/\.build/.*\.bundle$"; then
  echo "error: binary uses the native-build resource lookup; bundles in Contents/Resources would not be found" >&2
  exit 1
fi

sed -e "s/__VERSION__/${VERSION:-0.0.0-dev}/" -e "s/__BUILD_NUMBER__/${BUILD_NUMBER:-0}/" \
  Resources/Info.plist > "$app/Contents/Info.plist"

codesign --force --deep -s - "$app"
codesign --verify --strict "$app"
echo "Built $app ($config)"
