#!/bin/bash
set -e

echo "Building UART Emulator Demo for Windows..."
cd release/windows
./build-windows.sh
cd ../..

echo "✅ Windows build completed!"
