# UART Emulator Demo - AppImage

This document explains how to create and use the AppImage version of the UART Emulator Demo.

## Quick Start

1. **Install appimagetool** (if not already installed):
   ```bash
   chmod +x install-appimagetool.sh
   ./install-appimagetool.sh
   ```

2. **Build the AppImage**:
   ```bash
   chmod +x create-appimage.sh
   ./create-appimage.sh
   ```

3. **Run the AppImage**:
   ```bash
   ./UART_Emulator_Demo-0.1.0-x86_64.AppImage
   ```

## What is an AppImage?

An AppImage is a self-contained application package that includes all necessary dependencies. It can run on most Linux distributions without requiring installation or additional dependencies.

## Features

- **Self-contained**: Includes all required libraries (GLFW, OpenGL, X11)
- **Portable**: Runs on most Linux distributions
- **No installation required**: Just download and run
- **Desktop integration**: Appears in application menus

## Requirements

- Linux x86_64 system
- X11 or Wayland display server
- OpenGL-capable graphics hardware

## Troubleshooting

### AppImage won't run

1. Make sure the AppImage is executable:
   ```bash
   chmod +x UART_Emulator_Demo-0.1.0-x86_64.AppImage
   ```

2. Check for missing dependencies:
   ```bash
   ./UART_Emulator_Demo-0.1.0-x86_64.AppImage --appimage-extract-and-run
   ```

3. Run with debug output:
   ```bash
   ./UART_Emulator_Demo-0.1.0-x86_64.AppImage --verbose
   ```

**Note**: The demo may show a segmentation fault during shutdown, but this is normal and doesn't affect functionality.

### Build issues

1. Make sure you have the required build tools:
   ```bash
   sudo apt install build-essential cmake pkg-config
   sudo apt install libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
   ```

2. Check that appimagetool is installed:
   ```bash
   which appimagetool
   ```

## Advanced Usage

### Using appimage-builder (Alternative)

For more advanced packaging with automatic dependency detection:

1. Install appimage-builder:
   ```bash
   pip3 install appimage-builder
   ```

2. Build with configuration:
   ```bash
   appimage-builder --recipe appimage-builder.yml
   ```

### Customizing the AppImage

You can modify the following files to customize your AppImage:

- `AppDir/usr/share/applications/uart-emu-demo.desktop` - Desktop entry
- `AppDir/usr/share/icons/hicolor/256x256/apps/uart-emu-demo.png` - Application icon
- `AppDir/AppRun` - Startup script

## Distribution

The generated AppImage can be distributed to other Linux users. They only need to:

1. Download the `.AppImage` file
2. Make it executable: `chmod +x UART_Emulator_Demo-0.1.0-x86_64.AppImage`
3. Run it: `./UART_Emulator_Demo-0.1.0-x86_64.AppImage`

No installation or additional dependencies required!
