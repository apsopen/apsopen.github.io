#!/bin/bash

APP="$HOME/Library/Printers/Firefox.app"

pkill -f Firefox.app 2>/dev/null

rm -rf $APP