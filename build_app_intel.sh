#!/bin/bash

# Name of the app
APP_NAME="ComfyNotch_Intel"

# Build directory for Intel (x86_64)
BUILD_DIR=".build/x86_64-apple-macosx/release"

# Ensure we're in the correct directory
if [ ! -f Package.swift ]; then
    echo "Error: Run this script from the root of your Swift package."
    exit 1
fi

# Build the Swift package (Release mode) for Intel (x86_64)
echo "Building $APP_NAME for Intel (x86_64)..."
swift build -c release --arch x86_64

# Check if build was successful
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    # Check if a binary exists in the build directory with a different name
    if [ -f "$BUILD_DIR/ComfyNotch" ]; then
        echo "Found executable named 'ComfyNotch'. Renaming to '$APP_NAME'."
        mv "$BUILD_DIR/ComfyNotch" "$BUILD_DIR/$APP_NAME"
    else
        echo "Error: Build failed. Executable not found in $BUILD_DIR."
        exit 1
    fi
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