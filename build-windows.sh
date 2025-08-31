#!/bin/bash
set -e

echo "Building UART Emulator Demo for Windows..."
echo "=========================================="

# Check if Zig is installed
if ! command -v zig >/dev/null 2>&1; then
    echo "❌ Zig compiler not found."
    echo "Please install Zig first:"
    echo "  curl -L https://ziglang.org/download/latest/zig-linux-x86_64.tar.xz | tar xJ"
    echo "  sudo mv zig-linux-x86_64 /usr/local/zig"
    echo "  echo 'export PATH=/usr/local/zig:$PATH' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    exit 1
fi

echo "✅ Zig compiler found: $(zig version)"

# Check if we can cross-compile to Windows
echo "🔍 Checking Windows cross-compilation support..."
if ! zig targets | grep -q "x86_64-windows-gnu"; then
    echo "❌ Windows target not available in Zig."
    echo "Please update Zig to a newer version."
    exit 1
fi

echo "✅ Windows target available"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
make clean

# Build Windows demo
echo "🔨 Building Windows demo..."
make demo-windows

# Check if build was successful
if [ -f "bin/uart-demo.exe" ]; then
    echo "✅ Windows demo built successfully!"
    echo "📁 Output: bin/uart-demo.exe"
    echo "📏 Size: $(ls -lh bin/uart-demo.exe | awk '{print $5}')"
    
    # Create Windows distribution package
    echo "📦 Creating Windows distribution package..."
    mkdir -p dist/windows
    cp bin/uart-demo.exe dist/windows/
    
    # Create a simple batch file to run the demo
    cat > dist/windows/run-uart-demo.bat << 'EOF'
@echo off
echo Starting UART Emulator Demo...
echo.
echo If you see a black window, the demo is starting.
echo Press Escape to exit the demo.
echo.
pause
uart-demo.exe
pause
EOF
    
    # Create README for Windows users
    cat > dist/windows/README.txt << 'EOF'
UART Emulator Demo for Windows
==============================

This is a Windows build of the UART Emulator Demo.

Requirements:
- Windows 10 or later
- OpenGL-compatible graphics card
- No additional software installation required

How to run:
1. Double-click "run-uart-demo.bat" or
2. Open Command Prompt and run: uart-demo.exe

Features:
- UART hardware simulation
- Real-time communication visualization
- Modern GUI interface
- No installation required

Controls:
- Type text in the input field and press Enter to send
- Press Escape to exit
- Watch the UART communication in real-time

Troubleshooting:
- If the demo doesn't start, make sure your graphics drivers are up to date
- The demo requires OpenGL support
- Try running as administrator if you encounter permission issues

For more information, visit: https://github.com/Mathieu-Poirier/UART_EMU_V2
EOF
    
    echo "✅ Windows distribution package created: dist/windows/"
    echo ""
    echo "📋 Windows package contents:"
    echo "  - uart-demo.exe (main executable)"
    echo "  - run-uart-demo.bat (launcher script)"
    echo "  - README.txt (usage instructions)"
    echo ""
    echo "🎉 Windows build complete!"
    echo "You can now distribute the 'dist/windows/' folder to Windows users."
    
else
    echo "❌ Windows build failed!"
    echo "Check the error messages above."
    exit 1
fi
