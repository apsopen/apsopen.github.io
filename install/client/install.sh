#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BASE="$HOME/Library/Printers/mountain/client/main"
AGENT="$HOME/Library/LaunchAgents/com.mountain.client.plist"

mkdir -p "$BASE"
mkdir -p "$BASE/updates"

chmod 700 "$BASE"

echo "$1" > "$BASE/password"

chmod 600 "$BASE/password"


# The compiled Swift binary should be next to this installer
cp ./mountain-client "$BASE/mountain-client"

chmod 755 "$BASE/mountain-client"


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


launchctl bootstrap \
    "gui/$(id -u)" \
    "$AGENT"


echo "Mountain client installed"