# Windows Build Guide

This guide explains how to build the UART Emulator Demo for Windows.

## 🎯 Overview

The UART demo can be built for Windows using several methods:
1. **Cross-compilation from Linux** (requires additional setup)
2. **Native Windows build** (recommended)
3. **WSL (Windows Subsystem for Linux)** (easiest)

## 🚀 Quick Start - WSL (Recommended)

The easiest way to run the UART demo on Windows:

### 1. Install WSL
```powershell
# Open PowerShell as Administrator
wsl --install
```

### 2. Restart Windows and open WSL
```bash
# In WSL terminal
sudo apt update
sudo apt install build-essential cmake pkg-config
sudo apt install libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
```

### 3. Clone and build
```bash
git clone https://github.com/Mathieu-Poirier/UART_EMU_V2.git
cd UART_EMU_V2
make demo
./bin/demo
```

### 4. GUI Support
For GUI support in WSL, install an X11 server on Windows:
- Install VcXsrv or Xming
- Run the X11 server
- Set display: `export DISPLAY=:0`
- Run the demo

## 🔧 Native Windows Build

### Prerequisites

1. **Visual Studio Build Tools** or **MinGW-w64**
2. **GLFW library**
3. **OpenGL development libraries**

### Method 1: Visual Studio

1. **Install Visual Studio Build Tools**:
   - Download from: https://visualstudio.microsoft.com/downloads/
   - Install "C++ build tools" workload

2. **Download GLFW**:
   ```powershell
   # Download GLFW
   Invoke-WebRequest -Uri "https://github.com/glfw/glfw/releases/download/3.3.8/glfw-3.3.8.bin.WIN64.zip" -OutFile "glfw.zip"
   Expand-Archive -Path "glfw.zip" -DestinationPath "."
   ```

3. **Build the demo**:
   ```cmd
   # Open Developer Command Prompt
   cl /std:c++20 /EHsc /Iimgui /Iimgui/backends ^
      demo/uart_demo.cpp src/device.cpp ^
      imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp ^
      imgui/backends/imgui_impl_glfw.cpp imgui/backends/imgui_impl_opengl3.cpp ^
      /link glfw3.lib opengl32.lib gdi32.lib user32.lib kernel32.lib ^
      /out:uart-demo.exe
   ```

### Method 2: MinGW-w64

1. **Install MinGW-w64**:
   - Download from: https://www.mingw-w64.org/
   - Or use MSYS2: https://www.msys2.org/

2. **Install dependencies**:
   ```bash
   # In MSYS2
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

## 🔄 Cross-Compilation from Linux

### Prerequisites

1. **Zig compiler** (for cross-compilation)
2. **Windows libraries**

### Setup

1. **Install Zig**:
   ```bash
   curl -L https://ziglang.org/download/latest/zig-linux-x86_64.tar.xz | tar xJ
   sudo mv zig-linux-x86_64 /usr/local/zig
   echo 'export PATH=/usr/local/zig:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Download Windows libraries**:
   ```bash
   # Create Windows library directory
   mkdir -p windows-libs
   cd windows-libs
   
   # Download GLFW for Windows
   wget https://github.com/glfw/glfw/releases/download/3.3.8/glfw-3.3.8.bin.WIN64.zip
   unzip glfw-3.3.8.bin.WIN64.zip
   
   # Extract libraries to appropriate locations
   # This requires manual setup of library paths
   ```

3. **Build with cross-compilation**:
   ```bash
   ./build-windows.sh
   ```

## 📦 Distribution

### Creating Windows Package

1. **Build the executable** (using any method above)

2. **Create distribution package**:
   ```cmd
   mkdir uart-demo-windows
   copy uart-demo.exe uart-demo-windows\
   copy README.txt uart-demo-windows\
   
   # Create batch file launcher
   echo @echo off > uart-demo-windows\run-demo.bat
   echo echo Starting UART Demo... >> uart-demo-windows\run-demo.bat
   echo uart-demo.exe >> uart-demo-windows\run-demo.bat
   echo pause >> uart-demo-windows\run-demo.bat
   
   # Create ZIP
   powershell Compress-Archive -Path uart-demo-windows -DestinationPath uart-demo-windows.zip
   ```

### GitHub Release

Use the provided script:
```bash
./create-windows-release.sh
```

## 🐛 Troubleshooting

### Common Issues

1. **"GLFW library not found"**:
   - Ensure GLFW is properly installed
   - Check library paths
   - Use WSL as alternative

2. **"OpenGL not found"**:
   - Update graphics drivers
   - Install OpenGL development libraries

3. **"Entry point not found"**:
   - Use correct library versions
   - Check for 32-bit vs 64-bit mismatch

4. **GUI not displaying**:
   - In WSL: Install X11 server on Windows
   - Set DISPLAY environment variable
   - Check firewall settings

### Debug Build

For debugging, use debug flags:
```cmd
cl /std:c++20 /EHsc /Zi /Od /Iimgui /Iimgui/backends ^
   demo/uart_demo.cpp src/device.cpp ^
   imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp ^
   imgui/backends/imgui_impl_glfw.cpp imgui/backends/imgui_impl_opengl3.cpp ^
   /link glfw3.lib opengl32.lib gdi32.lib user32.lib kernel32.lib ^
   /out:uart-demo-debug.exe
```

## 🎯 Recommended Approach

For most users, **WSL** is the recommended approach because:
- ✅ No complex library setup required
- ✅ Uses the same build process as Linux
- ✅ Easy to maintain and update
- ✅ Full compatibility with existing code

For distribution purposes, **native Windows builds** are better because:
- ✅ No WSL installation required for end users
- ✅ Better performance
- ✅ Native Windows experience

## 📚 Additional Resources

- [GLFW Windows Guide](https://www.glfw.org/documentation.html)
- [OpenGL Windows Setup](https://www.opengl.org/wiki/Getting_Started)
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [MinGW-w64 Guide](https://www.mingw-w64.org/documentation/)
