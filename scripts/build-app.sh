#!/bin/bash
# Build build/Slotbar.app from the SwiftPM package and ad-hoc sign it (SPEC 12.2).
set -euo pipefail

config="${1:-debug}"
case "$config" in
  debug) arch_flags=() ;;
  # One universal build: build tools (SwiftTerm's build-info generator) come out universal too, so they run
  # on the build host. Per-arch builds compile them for the target arch, which an Intel runner cannot run.
  release) arch_flags=(--arch arm64 --arch x86_64) ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."

# Swift Build's resource accessor finds dependency bundles in Contents/Resources. The native build system
# (the default before Swift 6.4) looks next to Slotbar.app instead, so KeyboardShortcuts crashes in Settings.
build=(swift build --build-system swiftbuild)

app="build/Slotbar.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

"${build[@]}" -c "$config" ${arch_flags[@]+"${arch_flags[@]}"}
bin_dir="$("${build[@]}" -c "$config" ${arch_flags[@]+"${arch_flags[@]}"} --show-bin-path)"
cp "$bin_dir/Slotbar" "$app/Contents/MacOS/Slotbar"
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
