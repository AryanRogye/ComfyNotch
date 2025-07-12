#!/bin/bash

curl -s "https://api.github.com/repos/AryanRogye/ComfyNotch/releases?per_page=100" \
  | jq '[.[] .assets[] .download_count] | add'
