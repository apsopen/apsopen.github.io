#!/bin/bash

APP="$HOME/Library/Google/Chromium.app"

echo "Removing Chromium..."

# Close Chromium if running
pkill -f "Chromium.app" 2>/dev/null || true

# Remove copied application
rm -rf "$APP"
rm -rf "$HOME/Library/Google/.homebrew"
rm -rf "$HOME/Library/Google/Cask"
rm -rf "$HOME/Library/Caches/Homebrew"

echo "Chromium removed."