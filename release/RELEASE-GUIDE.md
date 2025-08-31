# GitHub Release Guide

This guide explains how to create GitHub releases for the UART Emulator Demo.

## 🚀 Quick Release Process

### 1. Build the AppImage
```bash
./create-appimage.sh
```

### 2. Create GitHub Release
```bash
./create-release.sh
```

That's it! The release script will automatically:
- Check if the AppImage exists
- Create professional release notes
- Upload the AppImage to GitHub
- Tag the release

## 📋 Manual Release Process

If you prefer to create releases manually:

### 1. Update Version
Edit `VERSION` file and update version in `create-release.sh`

### 2. Build AppImage
```bash
./create-appimage.sh
```

### 3. Commit Changes
```bash
git add .
git commit -m "Release vX.X.X"
git push origin main
```

### 4. Create Release via GitHub CLI
```bash
gh release create vX.X.X \
    --title "UART Emulator Demo vX.X.X" \
    --notes-file release-notes.md \
    UART_Emulator_Demo-X.X.X-x86_64.AppImage
```

### 5. Or Create via GitHub Web Interface
1. Go to: https://github.com/Mathieu-Poirier/UART_EMU_V2/releases
2. Click "Create a new release"
3. Choose a tag (e.g., v0.1.1)
4. Write release notes
5. Upload the AppImage file
6. Publish release

## 📝 Release Notes Template

```markdown
# UART Emulator Demo vX.X.X

## 🎉 What's New

### ✨ Features
- New feature 1
- New feature 2

### 🐛 Bug Fixes
- Fixed issue 1
- Fixed issue 2

### 🔧 Improvements
- Improved performance
- Better error handling

## 🚀 Quick Start

1. Download the AppImage file
2. Make it executable: `chmod +x UART_Emulator_Demo-X.X.X-x86_64.AppImage`
3. Run it: `./UART_Emulator_Demo-X.X.X-x86_64.AppImage`

## 📋 System Requirements

- Linux x86_64
- X11 or Wayland display server
- OpenGL-capable graphics hardware

## 📚 Documentation

See `README-AppImage.md` for detailed usage instructions.
```

## 🔄 Future Release Workflow

1. **Develop**: Make changes and test
2. **Version**: Update version numbers
3. **Build**: Create new AppImage
4. **Test**: Verify AppImage works
5. **Release**: Use automated script
6. **Announce**: Share on social media/forums

## 📦 AppImage Distribution

Once released, users can:
- Download directly from GitHub Releases
- Run without installation
- Share with other Linux users
- Integrate with AppImageHub

## 🛠️ Troubleshooting

### GitHub CLI Issues
```bash
# Re-authenticate
gh auth logout
gh auth login

# Check status
gh auth status
```

### AppImage Build Issues
```bash
# Clean and rebuild
make clean
./create-appimage.sh
```

### Release Creation Issues
```bash
# Check if tag exists
git tag -l

# Delete existing tag (if needed)
git tag -d vX.X.X
git push origin :refs/tags/vX.X.X
```

---

**Note**: Always test the AppImage before releasing!
