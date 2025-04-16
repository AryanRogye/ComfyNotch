#!/bin/bash
set -e

# === CONFIG ===
APP_NAME="ComfyNotch"                 # Final .app name
EXECUTABLE_NAME="ComfyNotchDev"      # Built binary from SwiftPM
BUILD_DIR=".build/release"
ENTITLEMENTS_FILE="ComfyNotch.entitlements"
ICON_SOURCE="Assets/ComfyNotchLogo.png"
ICONSET_DIR="Assets/ComfyNotchIcon.iconset"
ICNS_FILE="Assets/ComfyNotchIcon.icns"

# === CHECK ROOT ===
if [ ! -f Package.swift ]; then
    echo "❌ Error: Run this script from the root of your Swift package."
    exit 1
fi

# === BUILD ===
echo "🔨 Building $EXECUTABLE_NAME..."
swift build -c release

if [ ! -f "$BUILD_DIR/$EXECUTABLE_NAME" ]; then
    echo "❌ Error: Build failed. Executable $EXECUTABLE_NAME not found."
    exit 1
fi

# === CLEAN PREVIOUS ===
if [ -d "$APP_NAME.app" ]; then
    echo "🧹 Cleaning old $APP_NAME.app bundle..."
    rm -rf "$APP_NAME.app" "$APP_NAME.app.zip"
fi

# === CREATE APP STRUCTURE ===
echo "📁 Creating app bundle structure..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# === COPY BINARY ===
echo "📦 Adding executable..."
cp "$BUILD_DIR/$EXECUTABLE_NAME" "$APP_NAME.app/Contents/MacOS/$APP_NAME"
chmod +x "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# === GENERATE ICON ===
if [ -f "$ICON_SOURCE" ]; then
    echo "🎨 Generating .icns file..."
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png"
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png"
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png"
    sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png"
    sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png"
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png"
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png"
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png"
    cp "$ICON_SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"

    iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
    rm -rf "$ICONSET_DIR"

    if [ ! -f "$ICNS_FILE" ]; then
        echo "❌ Error: .icns file generation failed."
        exit 1
    fi

    cp "$ICNS_FILE" "$APP_NAME.app/Contents/Resources/"
else
    echo "❌ Error: Source icon not found at $ICON_SOURCE"
    exit 1
fi

# === INFO.PLIST ===
echo "🧾 Writing Info.plist..."
cat > "$APP_NAME.app/Contents/Info.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.aryanrogye.$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>ComfyNotchIcon</string>

    <key>NSCameraUsageDescription</key>
    <string>This app uses the camera for widget-related features.</string>
    <key>NSCameraUseContinuityCameraDeviceType</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>This app controls media playback.</string>
</dict>
</plist>
EOL

# === ENTITLEMENTS ===
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo "🔐 Creating entitlements file..."
    cat > "$ENTITLEMENTS_FILE" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>com.apple.MediaRemote</string>
    </array>
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.spotify.client</string>
        <string>com.apple.Music</string>
    </array>
</dict>
</plist>
EOL
else
    echo "✅ Entitlements file already exists."
fi

# === SIGN ===
echo "🔏 Signing app (adhoc)..."
codesign --deep --force --sign - --entitlements "$ENTITLEMENTS_FILE" "$APP_NAME.app"

# === CLEANUP ICON ===
rm -rf "$ICNS_FILE"

# === ZIP ===
echo "📦 Zipping app..."
ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$APP_NAME.app.zip"

echo "✅ Done! $APP_NAME.app.zip ready for GitHub Releases."
