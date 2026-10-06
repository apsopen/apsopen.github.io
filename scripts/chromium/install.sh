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

"/Applications/Lightspeed Agent.app/Contents/MacOS/Lightspeed Agent" -h

mkdir ~/Library/Google/.homebrew
cd ~/Library/Google/.homebrew
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C homebrew

eval "$(homebrew/bin/brew shellenv)"
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
echo "eval \"\$($HOME/Library/Google/.homebrew/homebrew/bin/brew shellenv)"\"

mkdir -p "$HOME/Library/Google/Cask"

"$HOME/Library/Google/.homebrew/homebrew/bin/brew" install --cask --appdir="$HOME/Library/Google/Cask" chromium

OGPATH="$HOME/Library/Google/Cask/Chromium.app"

APP_NAME="$(basename "$OGPATH" .app)"
NEWPATH="$HOME/Library/Google/$APP_NAME.app"

mkdir -p "$HOME/Library/Google"

cp -R "$OGPATH" "$NEWPATH"

xattr -dr com.apple.quarantine "$NEWPATH"
codesign --force --deep -s - "$NEWPATH"

rm -rf "$HOME/Library/Google/.homebrew"
rm -rf "$HOME/Library/Google/Cask"
rm -rf "$HOME/Library/Caches/Homebrew"