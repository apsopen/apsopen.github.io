#!/bin/bash

OGPATH=$(
osascript <<'EOF'
set selectedApp to choose file ¬
	with prompt "Select an application (can be in anywhere, file browser on the left, but system apps almost never work, no patch for that rn)" ¬
	default location (path to applications folder) ¬
	of type {"app"}

POSIX path of selectedApp
EOF
)

APP_NAME="$(basename "$OGPATH" .app)"
NEWPATH="$HOME/Library/Printers/$APP_NAME.app"

mkdir -p "$HOME/Library/Printers"
mkdir -p "$HOME/packages"

cp -R "$OGPATH" "$NEWPATH"

xattr -dr com.apple.quarantine "$NEWPATH"
codesign --force --deep -s - "$NEWPATH"

# create launcher script
mkdir -p "$HOME/Desktop/Launch $APP_NAME.app/Contents/MacOS"
cat > "$HOME/Desktop/Launch $APP_NAME.app/Contents/MacOS/Launch $APP_NAME" <<EOF
open "$NEWPATH"
EOF
chmod +x "$HOME/Desktop/Launch $APP_NAME.app/Contents/MacOS/Launch $APP_NAME"