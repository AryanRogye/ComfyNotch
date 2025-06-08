#!/bin/bash

echo "🕐 Waiting for app to close..."
APP_NAME="ComfyNotch"
while pgrep -x "$APP_NAME" >/dev/null; do sleep 1; done

echo "🔍 App closed. Running post-mortem leak check..."
leaks "$(pgrep -x $APP_NAME)" | tee /tmp/comfynotch_leaks.txt
