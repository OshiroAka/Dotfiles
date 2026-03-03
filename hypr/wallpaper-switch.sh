#!/bin/bash

IDS=(       
3613577930
3493394392
1706509671
)

CURRENT_FILE="/tmp/wallpaper_current"
LOCK_FILE="/tmp/wallpaper_lock"

if [ -f "$LOCK_FILE" ]; then
    exit 0
fi
touch "$LOCK_FILE"

if [ ! -f "$CURRENT_FILE" ]; then
    echo 0 > "$CURRENT_FILE"
fi

CURRENT=$(cat "$CURRENT_FILE")
NEXT=$(( (CURRENT + 1) % ${#IDS[@]} ))
echo $NEXT > "$CURRENT_FILE"

pkill -f linux-wallpaperengine
linux-wallpaperengine --screen-root eDP-1 --bg ${IDS[$NEXT]} --fps 60 &

rm "$LOCK_FILE"


