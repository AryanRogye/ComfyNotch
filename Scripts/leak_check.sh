#!/bin/bash

PID=$(pgrep -x ComfyNotch)
if [ -z "$PID" ]; then
  echo "❌ ComfyNotch not running."
  exit 1
fi
echo "🔍 Running leak check on PID $PID..."
leaks "$PID" | tee /tmp/comfynotch_leaks.txt
