#!/bin/bash
set -e

echo "Building UART Emulator Demo AppImage..."
cd release
./create-appimage.sh
cd ..

echo "✅ AppImage built successfully!"
echo "📁 AppImage location: release/UART_Emulator_Demo-0.1.0-x86_64.AppImage"
