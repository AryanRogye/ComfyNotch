# ComfyNotch Settings Structure

## Table of Contents
- [General](#general)
- [Notch](#notch)
  - [Notch Screen Options](#tabview-notch-screen-options)
  - [Widgets](#tabview-widgets)
- [WidgetSettings](#widgetsettings)
- [Animations](#animations)
- [Display](#display)
- [ComfyNotch](#comfynotch)

## General
- **Open Notch Dimensions**
  - Distance From Left
  - Distance From Right
  - Distance From Top
  - Max Notch Width
- **Closed Notch Settings**
  - Closed Notch Width
  - Fallback Notch Height
  - Hover Activation Area
    - Enable Music Controls On Hover
  - Hover Control Mode
  - Enable HUD (Volume/Brightness)
  - One Finger Action
  - Two Finger Action

## Notch
### TabView: Notch Screen Options
- **Top Control Customizations**
  - Pick a style (Dynamic / Simple) for: Home, Utils, FileTray, Messages
- **FileTray**
  - Pick Default Folder
  - Enable Localhost Sharing (QR Access)
    - ⚠️ Not encrypted; accessible by anyone on local network with PIN
    - Localhost Port Picker
    - Localhost PIN Field
- **Message Settings**
  - Enable Messages Notch View
    - Limit Most Recent Users (Toggle)
    - Max Messages Per User (Stepper/Input)
- **Utils Settings**
  - Enable Utils View
    - Enable Clipboard Listener

### TabView: Widgets
- **Currently Selected Widgets**
  - Drag & Drop Display Area (Widget Arrangement)
- **Select Widgets**
  - Toggle Each Widget
  - Access WidgetSettings Per Widget

## WidgetSettings
- **Music Player Widget Settings**
  - Player Style: Comfy / Native
  - Enable Album Flipping Animation
  - Show Music Provider
  - Music Controller Picker
    - If Media Remote:
      - Select Provider: Apple / Spotify
- **Camera Widget Settings**
  - Flip Camera
  - Camera Quality Picker (Many Options)
  - Enable Camera Overlay
    - Overlay Timer Picker (if enabled)
- **Event Widget Settings**
  - Scroll Up Threshold
  - Visual Display Option: Calendar / Reminder (Reminders coming soon)

## Animations
- **Notch Opening Animation**
  - Opening Style Picker: iOS Style / Spring
- **Metal GPU Rendering Settings**
  - ⚠️ Enabling may increase memory and CPU usage
  - Enable Metal Shaders (Toggle)
    - Notch Background Animation (Toggle)
    - Constant 120 FPS Mode (Toggle)

## Display
- **Select Screen (Display Picker)**
  - Info: “ComfyNotch works best with a screen that has a physical notch. A relaunch may be required to fully apply changes after switching displays.”

## ComfyNotch
- **License**
  - Full License Text
- **Updates**
  - App Logo
  - App Description
  - Version & Build Info
  - Release Notes
  - Check for Updates Button
