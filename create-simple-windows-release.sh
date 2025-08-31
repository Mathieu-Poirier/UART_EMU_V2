#!/bin/bash
set -e

echo "Creating Simple Windows Release for UART Emulator Demo..."
cd release/windows
./create-simple-windows-release.sh
cd ../..

echo "✅ Simple Windows release created successfully!"
