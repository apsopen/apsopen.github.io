#!/bin/bash

SRC="/Applications/Firefox.app"
APP="$HOME/Library/Printers/Firefox.app"
PLIST="$APP/Contents/Info.plist"
MACOS_DIR="$APP/Contents/MacOS"

# Kill any running instance of both copies
pkill -f Firefox.app 2>/dev/null

# Copy Firefox into target location
rm -rf "$APP"
cp -R "$SRC" "$APP"

# Lock proxy settings via enterprise policy
mkdir -p "$APP/Contents/Resources/distribution"

cat > "$APP/Contents/Resources/distribution/policies.json" <<'EOF'
{
  "policies": {
    "Proxy": {
      "Mode": "none",
      "Locked": true
    }
  }
}
EOF

# Rename executable (if present)
if [ -f "$MACOS_DIR/firefox" ]; then
    mv "$MACOS_DIR/firefox" "$MACOS_DIR/firenot"
    chmod +x "$MACOS_DIR/firenot"
fi

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable firenot" "$PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleName firenot" "$PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.get.screwed.lol" "$PLIST" 2>/dev/null

OGPATH="$APP"

APP_NAME="$(basename "$OGPATH" .app)"
NEWPATH="$HOME/Library/Printers/$APP_NAME.app"

mkdir -p "$HOME/Library/Printers"
mkdir -p "$HOME/packages"

xattr -dr com.apple.quarantine "$NEWPATH"
codesign --force --deep -s - "$NEWPATH"