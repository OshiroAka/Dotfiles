#!/bin/bash
set -e
sudo mkdir -p /usr/lib/qt6/qml/OshiroShell
sudo cp /home/oshiro/.config/quickshell/plugin/liboshiro.so /usr/lib/qt6/qml/OshiroShell/liboshiro.so
sudo bash -c 'echo "module OshiroShell
plugin oshiro" > /usr/lib/qt6/qml/OshiroShell/qmldir'
echo "✅ Plugin instalado em /usr/lib/qt6/qml/OshiroShell"
