#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-debug}"
case "$configuration" in debug|release) ;; *) echo "Usage: $0 [debug|release]" >&2; exit 2 ;; esac
swift build -c "$configuration"
bin_path="$(swift build -c "$configuration" --show-bin-path)"
app=".build/Rocket.app"
mkdir -p "$app/Contents/MacOS"
cp "$bin_path/Rocket" "$app/Contents/MacOS/Rocket"
cp Resources/Info.plist "$app/Contents/Info.plist"
# Local development only: this is not a notarized distribution build.
codesign --force --sign - --identifier io.github.s4na.rocket "$app"
/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Contents/Info.plist"
codesign --verify --strict "$app"
printf '\nBuilt %s\n' "$app"
