#!/bin/bash
set -e

echo "Creating Windows Release for UART Emulator Demo..."
cd release/windows
./create-windows-release.sh
cd ../..

echo "✅ Windows release created successfully!"
