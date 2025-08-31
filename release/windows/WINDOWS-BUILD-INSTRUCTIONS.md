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
