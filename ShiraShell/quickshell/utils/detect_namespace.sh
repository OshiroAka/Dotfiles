#!/bin/bash
# Detecta o namespace da layer do quickshell
hyprctl layers -j 2>/dev/null | python3 -c "
import json,sys
data = json.load(sys.stdin)
for monitor in data.values():
    for level in monitor.values():
        for layer in level:
            ns = layer.get('namespace','')
            if ns: print(ns)
" | sort -u
