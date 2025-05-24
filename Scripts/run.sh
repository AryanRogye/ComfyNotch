#!/bin/bash


pkill ComfyNotch
./Scripts/build.sh

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type f -name ComfyNotch -path '*Debug*/ComfyNotch.app/Contents/MacOS/ComfyNotch' \
    | sort -r \
    | head -n1)

if [[ -z "$APP_PATH" ]]; then
    echo "❌ Couldn't find built ComfyNotch binary."
    exit 1
fi

APP_BUNDLE="$(dirname "$(dirname "$(dirname "$APP_PATH")")")"

echo "✅ Launching: $APP_BUNDLE"
open -a "$APP_BUNDLE"
