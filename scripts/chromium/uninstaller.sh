#!/bin/bash

set -e

APP="$HOME/Applications/Chromium.app"

echo "Removing Chromium..."

# Close Chromium if running
pkill -f "Chromium.app" 2>/dev/null || true

# Remove copied application
rm -rf "$APP"

# Remove Homebrew-installed Chromium if present
if command -v brew >/dev/null 2>&1; then
    brew uninstall --cask chromium 2>/dev/null || true
fi

echo "Chromium removed."