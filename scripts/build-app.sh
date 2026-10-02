#!/usr/bin/env bash
# Builds a release binary and wraps it in olusage.app (menu-bar-only, no Dock icon).
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)/olusage"

APP="olusage.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/olusage"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>olusage</string>
  <key>CFBundleDisplayName</key><string>Ollama Usage</string>
  <key>CFBundleIdentifier</key><string>com.github.simple-mac-ollama-usage-widget</string>
  <key>CFBundleExecutable</key><string>olusage</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS will run it locally (and WebKit storage works).
codesign --force --sign - "$APP"
echo "Built $APP"
