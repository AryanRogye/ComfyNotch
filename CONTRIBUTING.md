# Contributing to ComfyNotch

Thanks for your interest in contributing! ComfyNotch is an open project focused on macOS UI utilities using SwiftUI, AppKit, and private system integrations. I'm building this mostly solo in my free time, so I'm prioritizing features I personally care about — and being upfront about what I'm *not* focusing on.

---

## Areas Where Help Is Needed

### Smooth Animations

If you're good at clean, interruptible animations, this is a huge area for improvement.

- `ComfyNotchView.swift` contains `.panGesture` code
- `ScrollHandler.swift` and object controls scroll behavior, snapping, and expansion logic

If you can help make transitions feel truly native/macOS-smooth, that would be a major contribution.


## What I'm Not Focusing On

- A plugin marketplace
- Live Activities not showing anything when no music is playing
  _(Fixing this requires touching animation logic — see `ScrollWidth.swift`, which has logic for this but is currently unused)_

If you're passionate about one of these or want to add anything yourself, go for it — I’ll likely review it unless it really doesn’t align with the project's direction.

---

## General Guidelines

1. Fork the repo and create a branch off `main`
2. Add comments when introducing new logic or views
3. For major features, open an issue or discussion first — I might already have a worktree in progress or abandoned

Thanks again for checking out ComfyNotch — feel free to reach out with ideas or questions.
