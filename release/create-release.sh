
#!/bin/bash
set -e

VERSION="0.1.0"
RELEASE_NAME="UART Emulator Demo v${VERSION}"
RELEASE_TAG="v${VERSION}"
APPIMAGE_FILE="UART_Emulator_Demo-${VERSION}-x86_64.AppImage"

echo "Creating GitHub Release for ${RELEASE_NAME}..."

# Check if AppImage exists
if [ ! -f "$APPIMAGE_FILE" ]; then
    echo "❌ AppImage not found: $APPIMAGE_FILE"
    echo "Please build it first with: ./create-appimage.sh"
    exit 1
fi

# Change to parent directory for git operations
cd ..

# Check if gh CLI is installed
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) not found."
    echo "Please install it first:"
    echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "  echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "  sudo apt update"
    echo "  sudo apt install gh"
    echo "  gh auth login"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

# Create release notes
cat > release-notes.md << 'EOF'
# UART Emulator Demo v0.1.0

## 🎉 First Release with AppImage Support!

This release includes a complete UART hardware simulation demo packaged as a portable AppImage.

### ✨ Features

- **UART Hardware Simulation**: Complete simulation of UART communication
- **ImGui Interface**: Modern, user-friendly GUI built with Dear ImGui
- **Real-time Communication**: Live UART transmission and reception
- **Portable AppImage**: Self-contained application that runs on most Linux distributions

### 📦 What's New

- **AppImage Packaging**: Easy distribution and installation
- **Desktop Integration**: Appears in application menus
- **Self-contained**: No additional dependencies required
- **Cross-distribution**: Works on Ubuntu, Fedora, Arch, and other Linux distributions

### 🚀 Quick Start

1. Download the AppImage file
2. Make it executable: `chmod +x UART_Emulator_Demo-0.1.0-x86_64.AppImage`
3. Run it: `./UART_Emulator_Demo-0.1.0-x86_64.AppImage`

### 🔧 For Developers

Build your own AppImage:
```bash
./install-appimagetool.sh
./create-appimage.sh
```

### 📋 System Requirements

- Linux x86_64
- X11 or Wayland display server
- OpenGL-capable graphics hardware

### ⚠️ Known Issues

- Cleanup segmentation fault during shutdown (doesn't affect functionality)
- Placeholder icon (can be replaced with custom icon)

### 📚 Documentation

See `README-AppImage.md` for detailed usage instructions.

---

**Download**: UART_Emulator_Demo-0.1.0-x86_64.AppImage
EOF

echo "✅ Release notes created: release-notes.md"

# Create the release
echo "Creating GitHub release..."
gh release create "$RELEASE_TAG" \
    --title "$RELEASE_NAME" \
    --notes-file release-notes.md \
    "$APPIMAGE_FILE"

echo "✅ Release created successfully!"
echo "📋 Release URL: https://github.com/Mathieu-Poirier/UART_EMU_V2/releases/tag/$RELEASE_TAG"

# Clean up
rm -f release-notes.md

echo ""
echo "🎉 Your UART Emulator Demo is now available on GitHub Releases!"
echo "Users can download and run the AppImage directly."
