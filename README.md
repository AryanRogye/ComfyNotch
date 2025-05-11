# 🚀 ComfyNotch

[![Swift](https://img.shields.io/badge/Swift-6.0.3-orange)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16.2-blue)](https://developer.apple.com/xcode/)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)](https://apple.com/macos/)

> Turn your MacBook’s notch into a **beautifully functional and customizable space**.

<img src="Assets/ComfyNotchLogo.png" alt="ComfyNotch Logo" width="200"/>


## 🎥 Live Demo

https://github.com/user-attachments/assets/03f213db-cb36-4a2b-92c2-c580f07ed741



_✨ Watch ComfyNotch bring your MacBook’s notch to life ✨_

> ⚠️ *Note:* This video shows a recent build, but ComfyNotch is under active development —  
> features and visuals might look a little different in your download!

## 📦 Download

> ⚠️ Not on the App Store (yet) — but super easy to run!

1. Go to the [**Releases tab**](https://github.com/AryanRogye/ComfyNotch/releases)
2. Download the latest `.dmg` file (e.g. `ComfyNotch-v0.1.0.dmg`)
3. Double-click to open it — **if macOS blocks it**, do:
   - Open **System Settings → Privacy & Security**
   - Scroll to **"Open Anyway"** under Security
   - Click it and you're good!

🧠 *Why?*  
I have a Developer ID, but I’m skipping the whole notarization + App Store process for now (too much red tape 🫠).  
macOS will warn you it’s “unverified,” but it’s totally safe — just follow the steps above ....

...or build it yourself from source (look for the script at the bottom 👇).

⚙️ *Heads up:* The manual build steps below work… mostly 😅  
But for the smoothest experience, just run [`scripts/build_app.sh`](scripts/build_app.sh) —  
it’s what I personally use, and it stays up to date because writing Bash with variables > retyping everything 10 times 💀

---

## 📖 About

ComfyNotch brings life to your MacBook’s notch by providing a clean and intuitive way to interact with widgets and other functionalities. It’s all about making your Mac **feel comfy and stylish**. 

---

## 🎉 Features

- ✅ **Widgets**: AI Integration, Music Player, Camera Widget, Notes, Time Display, and more!
- 🤖 **AI Chat**: Seamlessly interact with powerful AI models like OpenAI's GPT-4 directly from your notch
- 🎵 **Music Control**: Easily control your music playback with slick visual indicators.
- 📝 **Notes Widget**: Keep quick notes accessible from the notch.
- ⏰ **Time Widget**: Always know the time with style.
- 🔄 **Smooth Animations**: Every interaction feels satisfying.
- 📷 **Camera**: See how your looking in public
- 🎨 **Coming Soon: Customization**: Easily add your own widgets.

### 🪄 Smart Notch Hiding (You’ve never seen this before)

Hold down a modifier key (e.g. ⌘ or ⌥) and hover near the notch —  
ComfyNotch will temporarily hide itself so you can access toolbar elements underneath.

> Currently Not Working (cuz I reworked everything and wanna get a actual swiftpm to manage this)

Perfect for apps with chunky UIs like Xcode, Finder, or Final Cut.

> 🔥 Pretty sure no other notch utility does this.

## ⚠️ Known Issues

1. **macOS Compatibility**  
   - ComfyNotch only supports macOS 14 (Sonoma) and above.  
   - ComfyNotch also uses Metal for rendering, which is not available on macOS 13 and below.
   - Users on macOS 13 and below may experience crashes or missing functionalities.  
   - No plans for backward compatibility, but feel free to open an issue if needed.  

2. ** Monitor Switching (Solved) **  
   - Switching monitors causes the app to lose positioning, not returning to the laptop screen.  
   - Resolving this is also a priority.  

3. **Scroll Logic (for most MacOS)**

## 👏🏽 Fixed Issues
1. **Display Issues**  
   - After closing and reopening the laptop, the app display may appear distorted or glitchy.  
   - Fixing this is a priority once I know how to lol.


---

## ✅ **Planned Features & Improvements**

### 🔧 **Functionality Enhancements**
- [x] **App Restart on Display Changes**: Automatically restart the app when monitors are plugged in or unplugged.
- [x] **Hide App Icon**: Hide app icon at all times, no need to bother the users dock.
- [x] **Album View When Closed**: Display album art in a mini view when the panel is closed.
- [x] **Music Playing Indicator**: Add a smooth icon animation to indicate when music is playing.
- [x] **Multiple Notes System**: Implement a notes dashboard with multiple notes accessible through tabs.
- [x] **Dynamic Animated Button Colors**: Match the animated buttons’ colors to the dominant color of the album art.
- [x] **AI Chat Integration (More Coming Soon...)**: Allow users to interact with an AI chat feature by providing their own API keys.
- [ ] **Clipboard Manager**: Implement a clipboard manager to keep track of copied items.
- [ ] **Pomodoro Timer**: Add a Pomodoro timer to help users manage their time effectively.
- [ ] **Notifications Popup**: Right now there is a hover on the notch that pops down i'm sure we can reuse that for notifications
- [ ] **Better Shortcut Management**: Implement a better shortcut management system to allow users to customize their shortcuts easily.
- [ ] **File Tray**: Add a file tray to allow users to access their files easily.

### 🎨 **UI/UX Improvements**
- [x] **Better Settings Menu**: Revamp the settings view for easier customization and better user experience.
- [x] **Improved Notes Widget UI**: Add buttons to switch between multiple notes.
- [x] **Improved Music Player UI**: Make the buttons more cleaner.
- [x] **Convert to SwiftUI where I can**: Said everything I need to. 😂
- [x] **Invisible Mode**: Hide the notch with a shortcut when hovered on the notch, so toolbar options on other apps can be visible

---

## 📦 Installation

### 💻 **Clone and Build**
```bash
git clone https://github.com/YourUsername/ComfyNotch.git
cd ComfyNotch
open ComfyNotch.xcodeproj
```

- Open the project in Xcode
- Select the target `ComfyNotch` in the project navigator
- Build the project (Cmd + B)
- Run the project (Cmd + R)

- **Note:** You may need to set up your signing certificate in Xcode.
- Products > Archive > Distribute App > Developer ID
