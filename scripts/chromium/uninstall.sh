#!/bin/bash

set -e

APP="$HOME/Library/Printers/Chromium.app"

echo "Removing Chromium..."

# Close Chromium if running
pkill -f "Chromium.app" 2>/dev/null || true

# Remove copied application
rm -rf "$APP"

echo "Chromium removed."