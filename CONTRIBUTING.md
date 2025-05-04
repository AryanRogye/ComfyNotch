# Contributing to ComfyNotch

Thanks for your interest in contributing! ComfyNotch is an open project focused on macOS UI utilities using SwiftUI, AppKit, and private system integrations. I'm building this mostly solo in my free time, so I'm prioritizing features I personally care about — and being upfront about what I'm *not* focusing on.

---

## Currently Working on:
- ComfyCalendar (https://github.com/AryanRogye/ComfyCalendar)
- theres no real good calendar plugin for macOS, so i'm making a mini calendar plugin for ComfyNotch


## Areas Where Help Is Needed

### Smooth Animations

If you're good at clean, interruptible animations, this is a huge area for improvement.

- `ComfyNotchView.swift` contains `.panGesture` code
- `ScrollHandler.swift` controls scroll behavior, snapping, and expansion logic

If you can help make transitions feel truly native/macOS-smooth, that would be a major contribution.

### AI Plugin Support

Right now, AI integration only works with OpenAI.

- There's no support yet for Google or Anthropic
- I'd appreciate help making the plugin layer modular and easy to extend

### Bluetooth Support

Bluetooth currently does not connect or disconnect reliably. CoreBluetooth integration exists but is incomplete. If you can stabilize that, it would unlock more use cases.

---

## What I'm Not Focusing On

Some things I’m intentionally not spending time on right now:

- Accessibility and localization
- A plugin marketplace or theme engine
- Tiling window manager behavior or advanced automation

If you're passionate about one of these and want to contribute anyway, feel free — but I can’t promise I’ll review or merge it unless it aligns with the project's direction.

---

## General Guidelines

1. Fork the repo and create a branch off `main`
2. Follow existing code style and naming conventions
3. Keep PRs focused and small where possible
4. Add comments for complex logic
5. If you're adding a major feature, open an issue or discussion first

Thanks again for checking out ComfyNotch — feel free to reach out with ideas or questions.
