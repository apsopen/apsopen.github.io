#!/bin/bash

APP="$HOME/Library/Printers/Chromium.app"

echo "Removing Chromium..."

# Close Chromium if running
pkill -f "Chromium.app" 2>/dev/null || true

# Remove copied application
rm -rf "$APP"
rm -rf "$HOME/Library/Printers/.homebrew"
rm -rf "$HOME/Library/Printers/Cask"
rm -rf "$HOME/Library/Caches/Homebrew"

echo "Chromium removed."