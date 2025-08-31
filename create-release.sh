#!/bin/bash
set -e

echo "Creating GitHub Release for UART Emulator Demo..."
cd release
./create-release.sh
cd ..

echo "✅ Release created successfully!"
