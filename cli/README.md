# ComfyX CLI

A CLI tool for managing [ComfyNotch](https://github.com/AryanRogye/ComfyNotch) — built for indie macOS development workflows.

Easily handle builds, archives, app updates, and more through a fast and minimal interface.

## ✨ Features

- Archive and export macOS `.app` bundles
- (Coming Soon) Clean build artifacts
- Build in Debug or Release mode
- (Coming Soon) Generate Sparkle-compatible appcasts

> This project includes the [inih](https://github.com/benhoyt/inih) library, licensed under the MIT License.

## References (for finding again)

> FTXUI References:
- [FTXUI](https://github.com/ArthurSonzogni/FTXUI)
- [FTXUI - Menu](https://arthursonzogni.github.io/FTXUI/group__component.html#gad793a3a507766ffa711c4332a3815e24)
- [FTXUI - Input](https://arthursonzogni.github.io/FTXUI/group__component.html#ga7f285fcbc4dd0a0767b89a255fd062dc)

## 🛠️ Quickstart

1. **Edit your config:**

Create or edit `config/comfyx.ini` in your project. Example:

```ini
[build]
project = ../ComfyNotch.xcodeproj   ; Path to your .xcodeproj
scheme = ComfyNotch                 ; Xcode scheme to build

[archive]
archive_configuration = Release      ; Build configuration (Release/Debug)
archive_destructive = true           ; (Optional) Clean old archives/exports before building

[dmg]
dmg_name = ComfyNotch-Installer.dmg  ; Name for the DMG file (the .dmg file you distribute)
dmg_app_name = ComfyNotch.app         ; Name of the .app bundle inside the DMG
dmg_volume_name = ComfyNotch-Installer ; Volume name for DMG (the disk name shown when mounted)
dmg_move_from_archive = true          ; Copy .app from export to DMG folder
```

> **Tip:**
> - `dmg_name` is the filename of the DMG disk image (e.g. what you send to users).
> - `dmg_volume_name` is the name of the disk that appears in Finder when the DMG is opened (the window title and sidebar label).

2. **Add your ExportOptions.plist:**

Place your `ExportOptions.plist` in the `config/` folder (next to `comfyx.ini`). This file is required for the export step. Example:

```
config/
  comfyx.ini
  ExportOptions.plist
```

3. **Run the CLI:**

```sh
./bin/comfyx
```

All generated files (archives, exports, DMGs, logs) will be placed in the `ComfyXData/` folder in your project root.

- No need to set output paths—everything is organized for you!
- Edit the INI file to match your Xcode project and scheme.

4. **Install create-dmg:**

This tool requires the [`create-dmg`](https://github.com/create-dmg/create-dmg) utility. Install it via Homebrew:

```sh
brew install create-dmg
```

---
