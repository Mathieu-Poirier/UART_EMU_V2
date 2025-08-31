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
