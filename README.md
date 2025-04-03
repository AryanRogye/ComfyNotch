# 🚀 ComfyNotch

> Turn your MacBook’s notch into a **beautifully functional and customizable space**.

![ComfyNotch Logo](Assets/ComfyNotchLogo.png)

---

## 📖 About

ComfyNotch brings life to your MacBook’s notch by providing a clean and intuitive way to interact with widgets and other functionalities. It’s all about making your Mac **feel comfy and stylish**. 

---

## 🎉 Features

- ✅ **Widgets**: Music Player, Camera Widget, Notes, Time Display, and more!
- 🎵 **Music Control**: Easily control your music playback with slick visual indicators.
- 📝 **Notes Widget**: Keep quick notes accessible from the notch.
- ⏰ **Time Widget**: Always know the time with style.
- 🔄 **Smooth Animations**: Every interaction feels satisfying.
- 📷 **Camera**: See how your looking in public
- 🎨 **Coming Soon: Customization**: Easily add your own widgets.

## ⚠️ Known Issues

1. **macOS Compatibility**  
   - ComfyNotch only supports macOS 14 (Sonoma) and above.  
   - Users on macOS 13 and below may experience crashes or missing functionalities.  
   - No plans for backward compatibility, but feel free to open an issue if needed.  

2. **Display Issues**  
   - After closing and reopening the laptop, the app display may appear distorted or glitchy.  
   - Fixing this is a priority.  

3. **Monitor Switching**  
   - Switching monitors causes the app to lose positioning, not returning to the laptop screen.  
   - Resolving this is also a priority.  


---

## ✅ **Planned Features & Improvements**

### 🔧 **Functionality Enhancements**
- [ ] **App Restart on Display Changes**: Automatically restart the app when monitors are plugged in or unplugged.
- [x] **Hide App Icon**: Hide app icon at all times, no need to bother the users dock.
- [x] **Album View When Closed**: Display album art in a mini view when the panel is closed.
- [x] **Music Playing Indicator**: Add a smooth icon animation to indicate when music is playing.
- [ ] **Multiple Notes System**: Implement a notes dashboard with multiple notes accessible through tabs.
- [ ] **Dynamic Animated Button Colors**: Match the animated buttons’ colors to the dominant color of the album art.
- [ ] **AI Chat Integration**: Allow users to interact with an AI chat feature by providing their own API keys.

### 🎨 **UI/UX Improvements**
- [x] **Better Settings Menu**: Revamp the settings view for easier customization and better user experience.
- [ ] **Improved Notes Widget UI**: Add buttons to switch between multiple notes.
- [ ] **Improved Music Player UI**: Make the buttons more cleaner.
- [ ] **Convert to SwiftUI where I can**: Said everything I need to. 😂

---

## 📦 Installation

### 💻 **Clone and Build**
```bash
git clone https://github.com/YourUsername/ComfyNotch.git
cd ComfyNotch
./scripts/build_app.sh
```

### If you want to build manually:

```bash
git clone https://github.com/YourUsername/ComfyNotch.git
cd ComfyNotch
rm -rf ComfyNotch.app
rm -rf ComfyNotch.app.zip

mkdir -p ComfyNotch.app/Contents/MacOS
mkdir -p ComfyNotch.app/Contents/Resources

swift package clean
swift build -c release

# Copying the executable
cp .build/release/ComfyNotch ComfyNotch.app/Contents/MacOS/

# Making the executable executable
chmod +x ComfyNotch.app/Contents/MacOS/ComfyNotch

# Generating the icon files
mkdir -p "Assets/ComfyNotchIcon.iconset"

sips -z 16 16     "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_16x16.png"
sips -z 32 32     "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_16x16@2x.png"
sips -z 32 32     "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_32x32.png"
sips -z 64 64     "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_32x32@2x.png"
sips -z 128 128   "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_128x128.png"
sips -z 256 256   "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_128x128@2x.png"
sips -z 256 256   "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_256x256.png"
sips -z 512 512   "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_256x256@2x.png"
sips -z 512 512   "Assets/ComfyNotchLogo.png" --out "Assets/ComfyNotchIcon.iconset/icon_512x512.png"
cp "Assets/ComfyNotchLogo.png" "Assets/ComfyNotchIcon.iconset/icon_512x512@2x.png"

iconutil -c icns "Assets/ComfyNotchIcon.iconset" -o "Assets/ComfyNotchIcon.icns"
rm -rf "Assets/ComfyNotchIcon.iconset"

cp "Assets/ComfyNotchIcon.icns" "ComfyNotch.app/Contents/Resources/"

# Generating Info.plist
cat > ComfyNotch.app/Contents/Info.plist <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ComfyNotch</string>
    <key>CFBundleDisplayName</key>
    <string>ComfyNotch</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.ComfyNotch</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>ComfyNotch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>ComfyNotchIcon</string>
    <key>NSCameraUsageDescription</key>
    <string>ComfyNotch needs access to the camera for widget functionalities.</string>
    <key>NSCameraUseContinuityCameraDeviceType</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOL
```