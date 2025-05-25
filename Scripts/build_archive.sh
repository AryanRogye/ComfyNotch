#!/bin/bash

set -e

ARCHIVE_PATH="./Build/ComfyNotch.xcarchive"
EXPORT_PATH="./Build/Export"
EXPORT_OPTIONS_PLIST="./Scripts/ExportOptions.plist"

# Clean previous builds
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

# Archive
xcodebuild \
  -project ComfyNotch.xcodeproj \
  -scheme ComfyNotch \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  archive

# Export for direct distribution
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "✅ App archived and exported to $EXPORT_PATH"

mv "$EXPORT_PATH/ComfyNotch.app" ./
open .
