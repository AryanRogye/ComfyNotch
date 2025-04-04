#!/bin/bash

# Name of the app
APP_NAME="ComfyNotch"

# Build directory
BUILD_DIR=".build/release"

# Name of the entitlements file
ENTITLEMENTS_FILE="ComfyNotch.entitlements"

# Ensure we're in the correct directory
if [ ! -f Package.swift ]; then
    echo "Error: Run this script from the root of your Swift package."
    exit 1
fi

# Build the Swift package (Release mode)
echo "Building $APP_NAME..."
swift build -c release

# Check if build was successful
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo "Error: Build failed. Executable not found in $BUILD_DIR."
    exit 1
fi

# Clean previous build if it exists
if [ -d "$APP_NAME.app" ]; then
    rm -rf "$APP_NAME.app"
    rm -rf "$APP_NAME.app.zip"
    echo "Previous build removed."
fi

# Create .app bundle structure
echo "Creating $APP_NAME.app bundle..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy the executable to the .app bundle
cp "$BUILD_DIR/$APP_NAME" "$APP_NAME.app/Contents/MacOS/"
cp Info.plist "$APP_NAME.app/Contents/"


chmod +x "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# Generate .icns file from PNG
ICON_SOURCE="Assets/ComfyNotchLogo.png"
ICONSET_DIR="Assets/ComfyNotchIcon.iconset"
ICNS_FILE="Assets/ComfyNotchIcon.icns"

if [ -f "$ICON_SOURCE" ]; then
    echo "Generating .icns file from $ICON_SOURCE..."
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png"
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png"
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png"
    sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png"
    sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png"
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png"
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png"
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png"
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png"
    cp "$ICON_SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"

    iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
    rm -rf "$ICONSET_DIR"

    if [ -f "$ICNS_FILE" ]; then
        cp "$ICNS_FILE" "$APP_NAME.app/Contents/Resources/"
        echo ".icns file successfully created and added to the .app bundle."
    else
        echo "Error: Failed to create .icns file."
        exit 1
    fi
else
    echo "Error: Source icon file $ICON_SOURCE not found."
    exit 1
fi

# Create Info.plist file
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
    <string>com.yourname.$APP_NAME</string>
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

    <!-- Privacy Description -->
    <key>NSCameraUsageDescription</key>
    <string>ComfyNotch needs access to the camera for widget functionalities.</string>

    <!-- Continuity Camera -->
    <key>NSCameraUseContinuityCameraDeviceType</key>
    <true/>

    <!-- App Transport Security Settings -->
    <key>LSUIElement</key>
    <true/>

    <!-- Privacy Descriptions for Apple Event Access -->
    <key>NSAppleEventsUsageDescription</key>
    <string>ComfyNotch needs access to control Spotify and Music playback.</string>

</dict>
</plist>
EOL

# Create the Entitlements file if it doesn't exist
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    cat > "$ENTITLEMENTS_FILE" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Disable Sandbox (if not needed for App Store) -->
    <key>com.apple.security.app-sandbox</key>
    <false/>

    <!-- Temporary exception to access MediaRemote framework -->
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>com.apple.MediaRemote</string>
    </array>

    <!-- Allow Apple Event Access -->
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.spotify.client</string>
        <string>com.apple.Music</string>
    </array>
</dict>
</plist>
EOL
    echo "Entitlements file created successfully: $ENTITLEMENTS_FILE"
else
    echo "Entitlements file already exists: $ENTITLEMENTS_FILE"
fi

echo "Removing Icns file..."
rm -rf "$ICNS_FILE"

echo "App bundle created successfully!"

# ✅ 1. Sign the app (Ad-Hoc Signing) - Just copy-paste this command
codesign --deep --force --sign - --entitlements "$ENTITLEMENTS_FILE" ComfyNotch.app

# ✅ 2. Zip the app properly - This command keeps everything intact
ditto -c -k --sequesterRsrc --keepParent ComfyNotch.app ComfyNotch.app.zip

echo "Build complete! Upload ComfyNotch.app.zip to GitHub Releases."