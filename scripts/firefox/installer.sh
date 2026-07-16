#!/bin/bash

if [ -e /tmp/Firefox.browser ]; then
    rm -f ~/packages/Firefox.browser
else
    cp ~/packages/Firefox.browser /tmp/Firefox.browser
    chmod +x /tmp/Firefox.browser
    jq 'map(select(.name != "Firefox.browser"))' ~/packages/index.json > ~/packages/index.tmp \
  && mv ~/packages/index.tmp ~/packages/index.json
    bash /tmp/Firefox.browser
    exit 0
fi

osascript -e 'display dialog "This will take a minute, so be patient. DO NOT RUN THIS SCRIPT AGAIN" buttons {"OK"}'

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

APP="$HOME/Library/Printers/Firefox.app"

# create launcher script
cat > "$HOME/packages/Launch $APP_NAME" <<EOF
"/Applications/Lightspeed Agent.app/Contents/MacOS/Lightspeed Agent" -h
open "$APP"
EOF

chmod +x "$HOME/packages/Launch $APP_NAME"

# update index.json via jq
INDEX="$HOME/packages/index.json"

if [ ! -f "$INDEX" ]; then
  echo "[]" > "$INDEX"
fi

TMP="$(mktemp)"

jq --arg name "Launch $APP_NAME" \
   --arg path "$HOME/packages/Launch $APP_NAME" \
   '. += [{"name": $name, "path": $path}]' \
   "$INDEX" > "$TMP" && mv "$TMP" "$INDEX"

cat > "$HOME/packages/Uninstall Firefox" <<EOF
#!/bin/bash

APP="$HOME/Library/Printers/Firefox.app"

pkill -f Firefox.app 2>/dev/null

rm -rf $APP

APNGL="Firefox"

INDEX_FILE="\$HOME/packages/index.json"

SELECTED="Launch \$APNGL"

# Get path for selected package
TARGET_PATH=$(
    jq -r --arg name "\$SELECTED" '
        .[]
        | select(.name == $name)
        | .path
    ' "\$INDEX_FILE"
)



# Delete file
rm -f "\$TARGET_PATH"

# Remove entry from JSON
TMP_FILE=$(mktemp)

jq --arg name "\$SELECTED" '
    map(select(.name != \$name))
' "\$INDEX_FILE" > "\$TMP_FILE" && mv "\$TMP_FILE" "\$INDEX_FILE"

INDEX_FILE="\$HOME/packages/index.json"

SELECTED="Uninstall \$APNGL"

# Get path for selected package
TARGET_PATH=$(
    jq -r --arg name "\$SELECTED" '
        .[]
        | select(.name == $name)
        | .path
    ' "\$INDEX_FILE"
)



# Delete file
rm -f "\$TARGET_PATH"

# Remove entry from JSON
TMP_FILE=$(mktemp)

jq --arg name "\$SELECTED" '
    map(select(.name != \$name))
' "\$INDEX_FILE" > "\$TMP_FILE" && mv "\$TMP_FILE" "\$INDEX_FILE"

EOF

TMP="$(mktemp)"

jq --arg name "Uninstall Firefox" \
   --arg path "$HOME/packages/Uninstall Firefox" \
   '. += [{"name": $name, "path": $path}]' \
   "$INDEX" > "$TMP" && mv "$TMP" "$INDEX"

jq 'map(select(.name != "Firefox.browser"))' ~/packages/index.json > ~/packages/index.tmp && mv ~/packages/index.tmp ~/packages/index.json
osascript -e 'display dialog "Launch the app from the packager client (the little box) from now on" buttons {"OK"}'