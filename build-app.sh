#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build/arm64-apple-macosx/debug"
APP_DIR="$SCRIPT_DIR/WalkieClaude.app"
RESOURCES="$SCRIPT_DIR/Sources/WalkieClaude/Resources"

# Build
cd "$SCRIPT_DIR"
swift build

# Assemble .app bundle
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/WalkieClaude"           "$APP_DIR/Contents/MacOS/WalkieClaude"
cp "$SCRIPT_DIR/Info.plist"            "$APP_DIR/Contents/Info.plist"
cp "$RESOURCES/AppIcon.icns"           "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$RESOURCES/walkie-talkie.svg"      "$APP_DIR/Contents/Resources/walkie-talkie.svg"
cp "$RESOURCES/walkie-talkie.png"      "$APP_DIR/Contents/Resources/walkie-talkie.png"

# Copy resource bundle (contains SVG/PNG loaded via Bundle.module)
if [ -d "$BUILD_DIR/WalkieClaude_WalkieClaude.bundle" ]; then
    cp -r "$BUILD_DIR/WalkieClaude_WalkieClaude.bundle" "$APP_DIR/Contents/Resources/"
fi

# Install to /Applications
cp -r "$APP_DIR" /Applications/WalkieClaude.app

echo "✓ Built and installed WalkieClaude.app"
