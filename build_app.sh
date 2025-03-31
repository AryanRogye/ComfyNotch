#!/bin/bash

# Name of the app
APP_NAME="ComfyNotch"

# Build directory
BUILD_DIR=".build/release"

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
    echo "Previous build removed."
fi

# Create .app bundle structure
echo "Creating $APP_NAME.app bundle..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy the executable to the .app bundle
cp "$BUILD_DIR/$APP_NAME" "$APP_NAME.app/Contents/MacOS/"
chmod +x "$APP_NAME.app/Contents/MacOS/$APP_NAME"

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
</dict>
</plist>
EOL

echo "App bundle created successfully!"

# Launch the app (Optional)
echo "Launching $APP_NAME.app..."
open "$APP_NAME.app"
