#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_app>"
    exit 1
fi

path="$1"

lipo -archs "$path"/Contents/MacOS/ComfyNotch
