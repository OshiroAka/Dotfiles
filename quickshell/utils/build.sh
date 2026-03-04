#!/bin/bash
set -e
cd /home/oshiro/.config/quickshell
rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
echo "✅ Plugin compilado!"
