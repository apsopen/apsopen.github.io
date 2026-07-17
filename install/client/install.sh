#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BASE="$HOME/Library/Printers/mountain/client/main"
AGENT="$HOME/Library/LaunchAgents/com.mountain.client.plist"

echo "Removing previous installation..."

UID=$(id -u)

if launchctl print "gui/$UID/com.mountain.client" >/dev/null 2>&1; then
    echo "Stopping existing LaunchAgent..."
    launchctl bootout "gui/$UID" "$AGENT" 2>/dev/null || true
fi

pkill -f "$BASE/mountain-client" 2>/dev/null || true

if [ -d "$BASE" ]; then
    echo "Removing client files..."
    rm -rf "$BASE"
fi


if [ -f "$AGENT" ]; then
    echo "Removing LaunchAgent..."
    rm -f "$AGENT"
fi

echo "Installer directory: $SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/mountain-client" ]; then
    echo "Error: mountain-client not found in $SCRIPT_DIR"
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

cp "$SCRIPT_DIR/mountain-client" "$BASE/mountain-client"
chmod 755 "$BASE/mountain-client"


echo "Creating LaunchAgent..."

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>

    <key>Label</key>
    <string>com.mountain.client</string>

    <key>ProgramArguments</key>
    <array>
        <string>$BASE/mountain-client</string>
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
echo "Mountain client installed successfully"
echo "Installed to:"
echo "$BASE"

chown -R "$(whoami)" "$BASE"