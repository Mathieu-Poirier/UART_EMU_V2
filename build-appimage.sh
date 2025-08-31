#!/bin/bash
set -e

echo "Building UART Emulator Demo AppImage..."
cd release/linux
./create-appimage.sh
cd ../..

echo "✅ AppImage built successfully!"
echo "📁 AppImage location: release/linux/UART_Emulator_Demo-0.1.0-x86_64.AppImage"
