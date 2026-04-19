#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

# Get Qt6 QML install path
QT6_QML=$(qmlscene --version 2>/dev/null || true)
QT6_QML_DIR=$(python3 -c "import subprocess; r=subprocess.run(['qtpaths6','--install-prefix'],capture_output=True,text=True); print(r.stdout.strip())" 2>/dev/null || echo "/usr")
QT6_QML_DIR="$QT6_QML_DIR/lib/qt6/qml"

echo "📁 Qt6 QML dir: $QT6_QML_DIR"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$SCRIPT_DIR"     -DCMAKE_BUILD_TYPE=Release     -DCMAKE_INSTALL_PREFIX=/usr     -DQT6_INSTALL_QML="$QT6_QML_DIR"

make -j$(nproc)
sudo make install

echo ""
echo "✅ Plugin installed to $QT6_QML_DIR/ShiraOS"

#   _____ _     _                 
#  / ____| |   (_)                
# | (___ | |__  _ _ __ __ _       
#  \___ \| '_ \| | '__/ _` |      
#  ____) | | | | | | | (_| |      
# |_____/|_| |_|_|_|  \__,_|      
#
#/=================================\
#||   OShiroAKA > Shira           ||
#\=================================/