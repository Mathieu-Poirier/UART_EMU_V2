#!/bin/bash
set -e

echo "Building UART Emulator Demo for Windows (Simple Version)..."
echo "=========================================================="

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

echo ""
echo "⚠️  Note: This build requires Windows libraries to be available."
echo "   For a complete Windows build, you need to:"
echo ""
echo "   1. Download GLFW for Windows:"
echo "      wget https://github.com/glfw/glfw/releases/download/3.3.8/glfw-3.3.8.bin.WIN64.zip"
echo ""
echo "   2. Extract and place libraries in the correct location"
echo ""
echo "   3. Or use a Windows machine with Visual Studio/MinGW"
echo ""

# Create a Windows build script for manual use
cat > windows-build-manual.bat << 'EOF'
@echo off
echo Building UART Demo for Windows...
echo.

echo Installing dependencies...
echo You need to install:
echo - Visual Studio Build Tools or MinGW
echo - GLFW library
echo - OpenGL development libraries
echo.

echo Compiling...
g++ -std=c++20 -O3 -g ^
    -Iimgui -Iimgui/backends ^
    demo/uart_demo.cpp src/device.cpp ^
    imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp ^
    imgui/backends/imgui_impl_glfw.cpp imgui/backends/imgui_impl_opengl3.cpp ^
    -lglfw3 -lopengl32 -lgdi32 -luser32 -lkernel32 ^
    -o uart-demo.exe

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build successful!
    echo Run with: uart-demo.exe
) else (
    echo.
    echo ❌ Build failed!
    echo Check the error messages above.
)

pause
EOF

echo "✅ Created Windows build script: windows-build-manual.bat"
echo ""
echo "📋 Next steps for Windows build:"
echo ""
echo "Option 1: Manual Windows Build"
echo "  1. Copy this project to a Windows machine"
echo "  2. Install Visual Studio Build Tools or MinGW"
echo "  3. Download GLFW for Windows"
echo "  4. Run: windows-build-manual.bat"
echo ""
echo "Option 2: WSL (Windows Subsystem for Linux)"
echo "  1. Install WSL on Windows"
echo "  2. Run the Linux version in WSL"
echo "  3. Use X11 forwarding for GUI"
echo ""
echo "Option 3: Docker Windows Container"
echo "  1. Use Windows container with build tools"
echo "  2. Mount project directory"
echo "  3. Build inside container"
echo ""
echo "💡 For now, you can test the Linux version in WSL:"
echo "  wsl --install"
echo "  wsl"
echo "  ./bin/demo"
