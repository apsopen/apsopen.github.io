#!/bin/bash

APP="$HOME/.local/chromium/Chromium.app"

if [ ! -d "$APP" ]; then
    echo "Chromium is not installed."
    exit 1
fi

open "$APP" --args --no-proxy-server