#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${HERMES_TOKENBAR_APP:-$HOME/Applications/HermesTokenBar.app}"
BIN_SRC="$ROOT/.build/release/HermesTokenBar"
BIN_DST="$APP/Contents/MacOS/HermesTokenBar"

cd "$ROOT"
swift build -c release --product HermesTokenBar

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_SRC" "$BIN_DST"
chmod +x "$BIN_DST"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HermesTokenBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.musefantasy.HermesTokenBar</string>
    <key>CFBundleName</key>
    <string>HermesTokenBar</string>
    <key>CFBundleDisplayName</key>
    <string>HermesTokenBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
printf 'Installed %s\n' "$APP"
