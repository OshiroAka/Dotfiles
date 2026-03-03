#!/usr/bin/env fish
set state_file ~/.local/state/caelestia/scheme.json
set current (cat $state_file | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('mode','dark'))")
if test $current = dark
    caelestia scheme set -n pure-white -m light
else
    caelestia scheme set -n pure-white -m dark
end