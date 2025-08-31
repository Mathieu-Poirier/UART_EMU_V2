#!/bin/bash
set -e

echo "Installing appimagetool..."

# Check if already installed
if command -v appimagetool >/dev/null 2>&1; then
    echo "appimagetool is already installed at: $(which appimagetool)"
    exit 0
fi

# Download appimagetool
echo "Downloading appimagetool..."
wget -O appimagetool-x86_64.AppImage \
  https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage

# Make it executable
chmod +x appimagetool-x86_64.AppImage

# Move to system path
echo "Installing to /usr/local/bin..."
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool

echo "✅ appimagetool installed successfully!"
echo "You can now run: ./create-appimage.sh"
