#!/bin/bash
# Toggle overlay via socket
SOCK="/tmp/oshiro-qs.sock"
if command -v qs &> /dev/null; then
    qs ipc call toggle
else
    # Fallback: arquivo tmp
    F="/tmp/oshiro_overlay_open"
    [ -f "$F" ] && rm "$F" || touch "$F"
fi
