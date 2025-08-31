#!/bin/bash
set -e

echo "Creating Windows Release for UART Emulator Demo..."
cd release
./create-windows-release.sh
cd ..

echo "✅ Windows release created successfully!"
