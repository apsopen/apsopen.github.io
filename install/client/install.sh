#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BASE="$HOME/Library/Printers/tiled/open/main"
AGENT="$HOME/Library/LaunchAgents/com.tiled.open.plist"

echo "Removing previous installation..."

TYUUID=$(id -u)

if launchctl print "gui/$TYUUID/com.tiled.client" >/dev/null 2>&1; then
    echo "Stopping existing LaunchAgent..."
    launchctl bootout "gui/$TYUUID" "$AGENT" 2>/dev/null || true
fi

pkill -f "$BASE/tiled-client" 2>/dev/null || true

if [ -d "$BASE" ]; then
    echo "Removing client files..."
    rm -rf "$BASE"
fi


if [ -f "$AGENT" ]; then
    echo "Removing LaunchAgent..."
    rm -f "$AGENT"
fi

echo "Installer directory: $SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/tiled-client" ]; then
    echo "Error: tiled-client not found in $SCRIPT_DIR"
    exit 1
fi


echo "Creating directories..."

mkdir -p "$BASE"
mkdir -p "$BASE/updates"
mkdir -p "$HOME/Library/LaunchAgents"


echo "Storing password..."

if [ -z "$1" ]; then
    echo "Error: no password provided"
    echo "Usage: bash install.sh <password>"
    exit 1
fi

echo "$1" > "$BASE/password"
chmod 600 "$BASE/password"


echo "Installing client binary..."

cp "$SCRIPT_DIR/tiled-client" "$BASE/tiled-client"
chmod 755 "$BASE/tiled-client"


echo "Creating LaunchAgent..."

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>

    <key>Label</key>
    <string>com.tiled.client</string>

    <key>ProgramArguments</key>
    <array>
        <string>$BASE/tiled-client</string>
    </array>

    <key>WorkingDirectory</key>
    <string>$BASE</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$BASE/client.log</string>

    <key>StandardErrorPath</key>
    <string>$BASE/client.error.log</string>

</dict>
</plist>
EOF


echo "Loading LaunchAgent..."

# Remove existing version if present
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true

# Load new version
launchctl bootstrap \
    "gui/$(id -u)" \
    "$AGENT"


echo ""
echo "tiled client installed successfully"
echo "Installed to:"
echo "$BASE"

chown -R "$(whoami)" "$BASE"