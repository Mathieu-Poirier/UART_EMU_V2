#!/bin/bash
set -e

VERSION="0.1.0"
RELEASE_NAME="UART Emulator Demo v${VERSION} - Windows"
RELEASE_TAG="v${VERSION}-windows"
WINDOWS_ZIP="UART_Emulator_Demo-${VERSION}-Windows-x64.zip"

echo "Creating Windows Release for ${RELEASE_NAME}..."

# Check if we're in the right directory
if [ ! -f "../../Makefile" ]; then
    echo "❌ Please run this script from the release/windows/ directory"
    exit 1
fi

# Change to parent directory
cd ../..

# Create Windows build instructions
echo "📋 Creating Windows build instructions..."

# Create a comprehensive Windows build guide
cat > release/windows/WINDOWS-BUILD-INSTRUCTIONS.md << 'EOF'
# Windows Build Instructions

## 🎯 Quick Start - WSL (Recommended)

The easiest way to run the UART demo on Windows:

### 1. Install WSL
```powershell
# Open PowerShell as Administrator
wsl --install
```

### 2. In WSL, build and run
```bash
sudo apt update
sudo apt install build-essential cmake pkg-config
sudo apt install libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev

git clone https://github.com/Mathieu-Poirier/UART_EMU_V2.git
cd UART_EMU_V2
make demo
./bin/demo
```

## 🔧 Native Windows Build

### Prerequisites
- Visual Studio Build Tools or MinGW-w64
- GLFW library for Windows
- OpenGL development libraries

### Method 1: Visual Studio

1. **Install Visual Studio Build Tools**:
   - Download from: https://visualstudio.microsoft.com/downloads/
   - Install "C++ build tools" workload

2. **Download GLFW**:
   ```powershell
   Invoke-WebRequest -Uri "https://github.com/glfw/glfw/releases/download/3.3.8/glfw-3.3.8.bin.WIN64.zip" -OutFile "glfw.zip"
   Expand-Archive -Path "glfw.zip" -DestinationPath "."
   ```

3. **Build the demo**:
   ```cmd
   cl /std:c++20 /EHsc /Iimgui /Iimgui/backends ^
      demo/uart_demo.cpp src/device.cpp ^
      imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp ^
      imgui/backends/imgui_impl_glfw.cpp imgui/backends/imgui_impl_opengl3.cpp ^
      /link glfw3.lib opengl32.lib gdi32.lib user32.lib kernel32.lib ^
      /out:uart-demo.exe
   ```

### Method 2: MinGW-w64

1. **Install MSYS2**:
   - Download from: https://www.msys2.org/

2. **Install dependencies**:
   ```bash
   pacman -S mingw-w64-x86_64-gcc
   pacman -S mingw-w64-x86_64-glfw
   pacman -S mingw-w64-x86_64-opengl-headers
   ```

3. **Build the demo**:
   ```bash
   g++ -std=c++20 -O3 -g \
       -Iimgui -Iimgui/backends \
       demo/uart_demo.cpp src/device.cpp \
       imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp \
       imgui/backends/imgui_impl_glfw.cpp imgui/backends/imgui_impl_opengl3.cpp \
       -lglfw3 -lopengl32 -lgdi32 -luser32 -lkernel32 \
       -o uart-demo.exe
   ```

## 📦 Creating Windows Package

After building the executable:

1. **Create distribution folder**:
   ```cmd
   mkdir uart-demo-windows
   copy uart-demo.exe uart-demo-windows\
   ```

2. **Create launcher script**:
   ```cmd
   echo @echo off > uart-demo-windows\run-demo.bat
   echo echo Starting UART Demo... >> uart-demo-windows\run-demo.bat
   echo uart-demo.exe >> uart-demo-windows\run-demo.bat
   echo pause >> uart-demo-windows\run-demo.bat
   ```

3. **Create ZIP package**:
   ```powershell
   Compress-Archive -Path uart-demo-windows -DestinationPath uart-demo-windows.zip
   ```

## 🐛 Troubleshooting

- **"GLFW library not found"**: Ensure GLFW is properly installed
- **"OpenGL not found"**: Update graphics drivers
- **GUI not displaying**: In WSL, install X11 server on Windows

## 💡 Recommendation

Use WSL for the easiest experience:
- No complex library setup
- Same build process as Linux
- Full compatibility
EOF

# Create a simple batch file for Windows users
cat > release/windows/build-windows.bat << 'EOF'
@echo off
echo Building UART Demo for Windows...
echo.

echo Prerequisites:
echo - Visual Studio Build Tools or MinGW-w64
echo - GLFW library for Windows
echo - OpenGL development libraries
echo.

echo For detailed instructions, see: WINDOWS-BUILD-INSTRUCTIONS.md
echo.

echo Quick WSL method (recommended):
echo 1. Install WSL: wsl --install
echo 2. In WSL: sudo apt install build-essential libglfw3-dev libgl1-mesa-dev
echo 3. In WSL: make demo && ./bin/demo
echo.

pause
EOF

# Create a simple launcher script
cat > release/windows/run-demo-wsl.bat << 'EOF'
@echo off
echo Starting UART Demo via WSL...
echo.

echo If WSL is not installed, run: wsl --install
echo.

wsl bash -c "cd /mnt/c/path/to/UART_EMU_V2 && make demo && ./bin/demo"
pause
EOF

# Create Windows distribution package
echo "📦 Creating Windows distribution package..."
mkdir -p release/windows/dist
cp release/windows/WINDOWS-BUILD-INSTRUCTIONS.md release/windows/dist/
cp release/windows/build-windows.bat release/windows/dist/
cp release/windows/run-demo-wsl.bat release/windows/dist/

# Create README for Windows users
cat > release/windows/dist/README.txt << 'EOF'
UART Emulator Demo for Windows
==============================

This package contains build instructions and tools for running the UART Emulator Demo on Windows.

## 🚀 Quick Start (Recommended)

### Option 1: WSL (Easiest)
1. Install WSL: Open PowerShell as Administrator and run: wsl --install
2. Restart Windows
3. In WSL terminal: sudo apt install build-essential libglfw3-dev libgl1-mesa-dev
4. Clone the repository and build: make demo && ./bin/demo

### Option 2: Native Windows Build
1. Follow the instructions in WINDOWS-BUILD-INSTRUCTIONS.md
2. Install Visual Studio Build Tools or MinGW-w64
3. Download GLFW library
4. Build using the provided commands

## 📋 Package Contents

- WINDOWS-BUILD-INSTRUCTIONS.md - Detailed build guide
- build-windows.bat - Windows build helper script
- run-demo-wsl.bat - WSL launcher script
- README.txt - This file

## 🎯 Features

- UART hardware simulation
- Real-time communication visualization
- Modern GUI interface
- Cross-platform compatibility

## 🔗 More Information

- GitHub Repository: https://github.com/Mathieu-Poirier/UART_EMU_V2
- Linux AppImage: Available in the main release
- Issues: Report problems on GitHub

## 💡 Tips

- WSL provides the easiest Windows experience
- No complex library setup required
- Full compatibility with Linux version
- GUI works with X11 server (VcXsrv, Xming)
EOF

# Create ZIP package
cd release/windows/dist
zip -r "../../../${WINDOWS_ZIP}" .
cd ../../..

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

## 🎉 Windows Support Added!

This release provides Windows build instructions and tools for the UART Emulator Demo.

### ✨ What's New

- **Windows Build Instructions**: Complete guide for building on Windows
- **WSL Support**: Easy Windows experience using WSL
- **Native Windows Build**: Instructions for Visual Studio and MinGW
- **Build Scripts**: Helper scripts for Windows development

### 🚀 Quick Start

#### Option 1: WSL (Recommended)
1. Install WSL: `wsl --install`
2. In WSL: `sudo apt install build-essential libglfw3-dev libgl1-mesa-dev`
3. Build and run: `make demo && ./bin/demo`

#### Option 2: Native Windows Build
1. Follow instructions in `WINDOWS-BUILD-INSTRUCTIONS.md`
2. Install Visual Studio Build Tools or MinGW-w64
3. Download GLFW library
4. Build using provided commands

### 📋 System Requirements

- Windows 10 or later
- WSL (recommended) or Visual Studio/MinGW
- OpenGL-compatible graphics card

### 🔧 For Developers

Build your own Windows version:
```bash
# Using WSL (easiest)
wsl
make demo

# Native Windows (see instructions)
# Follow WINDOWS-BUILD-INSTRUCTIONS.md
```

### 📦 Package Contents

- `WINDOWS-BUILD-INSTRUCTIONS.md` - Detailed build guide
- `build-windows.bat` - Windows build helper
- `run-demo-wsl.bat` - WSL launcher script
- `README.txt` - Usage instructions

### ⚠️ Known Issues

- Cross-compilation requires additional library setup
- Native Windows build requires manual library installation
- WSL provides the most reliable experience

### 🔗 Related Releases

- [Linux AppImage](https://github.com/Mathieu-Poirier/UART_EMU_V2/releases/tag/v0.1.0)

### 💡 Recommendation

**Use WSL** for the easiest Windows experience:
- No complex library setup
- Same build process as Linux
- Full compatibility
- GUI support with X11 server

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
echo "Users can download the package and follow the build instructions."
