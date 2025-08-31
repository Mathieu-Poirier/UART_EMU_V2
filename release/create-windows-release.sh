#!/bin/bash
set -e

VERSION="0.1.0"
RELEASE_NAME="UART Emulator Demo v${VERSION} - Windows"
RELEASE_TAG="v${VERSION}-windows"
WINDOWS_ZIP="UART_Emulator_Demo-${VERSION}-Windows-x64.zip"

echo "Creating Windows Release for ${RELEASE_NAME}..."

# Check if we're in the right directory
if [ ! -f "../Makefile" ]; then
    echo "❌ Please run this script from the release/ directory"
    exit 1
fi

# Change to parent directory
cd ..

# Build Windows demo
echo "Building Windows demo..."
./build-windows.sh

# Check if Windows build was successful
if [ ! -f "dist/windows/uart-demo.exe" ]; then
    echo "❌ Windows build failed. Please run ./build-windows.sh first."
    exit 1
fi

# Create Windows release package
echo "Creating Windows release package..."
cd dist/windows
zip -r "../../${WINDOWS_ZIP}" .
cd ../..

# Check if gh CLI is installed
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) not found."
    echo "Please install it first or create the release manually."
    echo "Windows package created: ${WINDOWS_ZIP}"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    echo "Windows package created: ${WINDOWS_ZIP}"
    exit 1
fi

# Create release notes
cat > windows-release-notes.md << 'EOF'
# UART Emulator Demo v0.1.0 - Windows

## 🎉 Windows Release!

This is the Windows version of the UART Emulator Demo, built using cross-compilation from Linux.

### ✨ Features

- **UART Hardware Simulation**: Complete simulation of UART communication
- **ImGui Interface**: Modern, user-friendly GUI built with Dear ImGui
- **Real-time Communication**: Live UART transmission and reception
- **Windows Native**: Built specifically for Windows x64

### 🚀 Quick Start

1. Download and extract the ZIP file
2. Double-click `run-uart-demo.bat` or run `uart-demo.exe` directly
3. Type text in the input field and press Enter to send
4. Watch the UART communication in real-time

### 📋 System Requirements

- Windows 10 or later (x64)
- OpenGL-compatible graphics card
- No additional software installation required

### 🔧 For Developers

Build your own Windows version:
```bash
./build-windows.sh
```

### 📦 Package Contents

- `uart-demo.exe` - Main executable
- `run-uart-demo.bat` - Launcher script
- `README.txt` - Usage instructions

### ⚠️ Known Issues

- Cleanup segmentation fault during shutdown (doesn't affect functionality)
- Requires OpenGL support

### 🔗 Related Releases

- [Linux AppImage](https://github.com/Mathieu-Poirier/UART_EMU_V2/releases/tag/v0.1.0)

---

**Download**: UART_Emulator_Demo-0.1.0-Windows-x64.zip
EOF

echo "✅ Release notes created: windows-release-notes.md"

# Create the release
echo "Creating GitHub release..."
gh release create "$RELEASE_TAG" \
    --title "$RELEASE_NAME" \
    --notes-file windows-release-notes.md \
    "$WINDOWS_ZIP"

echo "✅ Windows release created successfully!"
echo "📋 Release URL: https://github.com/Mathieu-Poirier/UART_EMU_V2/releases/tag/$RELEASE_TAG"

# Clean up
rm -f windows-release-notes.md

echo ""
echo "🎉 Windows release is now available on GitHub!"
echo "Users can download and run the Windows executable directly."
