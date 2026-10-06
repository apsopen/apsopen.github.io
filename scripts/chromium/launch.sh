#!/bin/bash

APP="$HOME/Library/Google/Chromium.app"

if [ ! -d "$APP" ]; then
    echo "Chromium is not installed."
    exit 1
fi

open "$APP" --args --no-proxy-server