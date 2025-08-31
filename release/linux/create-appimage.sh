#!/bin/bash
set -e

echo "Building UART Emulator Demo AppImage..."

# Build the demo
echo "Building demo application..."
cd ../..
make clean
make demo
cd release/linux

# Create AppDir
echo "Creating AppDir structure..."
rm -rf AppDir
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps

# Copy binary
echo "Copying binary..."
cp ../../bin/demo AppDir/usr/bin/uart-emu-demo

# Create desktop entry
echo "Creating desktop entry..."
cat > AppDir/usr/share/applications/uart-emu-demo.desktop << 'EOF'
[Desktop Entry]
Name=UART Emulator Demo
Comment=UART Hardware Simulation Demo
Exec=uart-emu-demo
Icon=uart-emu-demo
Terminal=false
Type=Application
Categories=Development;Education;
EOF

# Also create desktop file in root for appimagetool
cp AppDir/usr/share/applications/uart-emu-demo.desktop AppDir/uart-emu-demo.desktop

# Create AppRun
echo "Creating AppRun script..."
cat > AppDir/AppRun << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}"/usr/bin/:"${PATH}"
export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${LD_LIBRARY_PATH}"
exec "${HERE}"/usr/bin/uart-emu-demo "$@"
EOF

chmod +x AppDir/AppRun

# Create simple icon using ImageMagick if available, otherwise create a text file
echo "Creating icon..."
if command -v convert >/dev/null 2>&1; then
    convert -size 256x256 xc:transparent -fill blue -draw "circle 128,128 128,64" \
      -fill white -pointsize 40 -annotate +80+120 "UART" \
      AppDir/usr/share/icons/hicolor/256x256/apps/uart-emu-demo.png
    echo "Icon created using ImageMagick"
else
    echo "ImageMagick not found, creating placeholder icon..."
    # Create a simple text-based icon placeholder
    echo "UART" > AppDir/usr/share/icons/hicolor/256x256/apps/uart-emu-demo.png
fi

# Copy icon to root for appimagetool
cp AppDir/usr/share/icons/hicolor/256x256/apps/uart-emu-demo.png AppDir/uart-emu-demo.png

# Use appimagetool to create AppImage
echo "Creating AppImage..."
if command -v appimagetool >/dev/null 2>&1; then
    appimagetool AppDir UART_Emulator_Demo-0.1.0-x86_64.AppImage
    echo "✅ AppImage created successfully: UART_Emulator_Demo-0.1.0-x86_64.AppImage"
    echo "You can now run it with: ./UART_Emulator_Demo-0.1.0-x86_64.AppImage"
else
    echo "❌ appimagetool not found. Please install it first:"
    echo "wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    echo "chmod +x appimagetool-x86_64.AppImage"
    echo "sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
    echo ""
    echo "Then run this script again."
    exit 1
fi
