#!/bin/bash
set -e

if [[ ! -f "ComfyNotch.xcodeproj/project.pbxproj" ]]; then
    echo "❌ Not in the ComfyNotch root directory. Aborting."
    exit 1
fi

rm -rf ComfyNotch.app
rm -rf ComfyNotch.zip
rm -rf Build/
