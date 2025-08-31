#!/bin/bash
set -e

echo "Creating GitHub Release for UART Emulator Demo..."
cd release/linux
./create-release.sh
cd ../..

echo "✅ Release created successfully!"
