#!/bin/bash
cd /home/oshiro/.config/quickshell
mkdir -p build
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/
cmake --build build
cmake --install build --prefix /
echo "Plugin compilado em /home/oshiro/.config/quickshell/plugin/"
echo "liboshiro-region.so e qmldir prontos"
