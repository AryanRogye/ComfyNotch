pkill ComfyNotch
./Scripts/build.sh
open "$(find ~/Library/Developer/Xcode/DerivedData -type d -name 'ComfyNotch.app' -path '*Debug*' | sort -r | head -n1)"
