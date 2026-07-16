#!/bin/bash

set -e

INSTALL_DIR="$HOME/Applications/Chromium"

echo "Installing Chromium..."

# Ensure Homebrew exists
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Load Homebrew environment
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Install Chromium
brew install --cask chromium

echo "Copying Chromium to user Applications folder..."

mkdir -p "$HOME/Applications"

rm -rf "$INSTALL_DIR.app"

cp -R "/Applications/Chromium.app" "$INSTALL_DIR.app"

# Remove quarantine flag
xattr -dr com.apple.quarantine "$INSTALL_DIR.app" 2>/dev/null || true

echo ""
echo "Chromium installed:"
echo "$INSTALL_DIR.app"