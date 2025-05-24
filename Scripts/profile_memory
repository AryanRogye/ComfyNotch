#!/bin/bash


APP_NAME="ComfyNotch"

PID=$(pgrep -x "$APP_NAME")

if [ -z "$PID" ]; then
  echo "❌ $APP_NAME is not running."
  exit 1
fi

echo "📈 Monitoring memory for PID $PID ($APP_NAME)..."
echo "Press Ctrl+C to stop."
echo ""

while true; do
  TIMESTAMP=$(date "+%H:%M:%S")
  MEM_USAGE=$(ps -o rss= -p "$PID")
  MEM_MB=$(echo "scale=2; $MEM_USAGE / 1024" | bc)
  echo "[$TIMESTAMP] Memory: ${MEM_MB} MB"
  sleep 2
done
