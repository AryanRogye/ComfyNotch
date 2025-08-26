#### August 8th 2025

<details>
  <summary> View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/2ea1cbb"><code>2ea1cbb</code></a> </summary>

  - Added back re_align_notch into new Implementation of the notch 
  - Added back HUD Live Activities into the notch
  - Added a Space Manager 

</details>

---

#### August 9th 2025

<details>
  <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/80c47c0"><code>80c47c0</code></a></summary>

  - Added Back Fallback Notch Functionality
  - NotchSpaceManager
    - Made sure that space manager wont cause the notch to not show up
    - Fixed issue with re aligned notch
  - Added in onTapGesture to open the Notch
  - Removed the context menu for now, gonna add back once I remove the touch controls
  - Fixed widget spacing logic for ComfyNotchStyleMusicWidget

</details>

---

#### August 10th 2025
<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/c122214"><code>c122214</code></a></summary>

  - Internal cleanup of files
  - Fixed spacing issue of widgets, mostly cuz of topNotchView not being aligned properly
  - Fixed issue with the eventTap crashing when clicking random things when nothing was showing
  - cleaned up unnecessary HomeNotchView renders, where I was doing HStack(spacing: 0) with more Hstacks
  - Fixed a UI bug with the ComfyNotchStyleMusicWidget where it wouldnt be centered for the album

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/3d4320e"><code>3d4320e</code></a></summary>

  - Fixing mini Issues with the scroll manager
    - when hovering and oepning shows unnecessary fadeaway aniations
    - when closing would close then readjust the notch if music was playing, but now we flow into it
    - Thinking about new logic for the whole animation, where I wouldnt have to think much about it

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/973a4e8"><code>973a4e8</code></a></summary>

  - Fixed display settings, to now where if I change the selected display, you have to click save to apply the changes
    - Changes are now updated right away, no more weird warning about having to restart the app for changes to take effect
  - Because of fixing the display settings, I found out that when calculating the height of the notch, i could also take into account the menu bar item heights:
    ```swift
        func getMenuBarHeight(for screen: NSScreen? = NSScreen.main) -> CGFloat {
            guard let screen = screen else { return 0 }
            
            let screenFrame = screen.frame
            let visibleFrame = screen.visibleFrame
                
            // The difference between the full screen height and the visible height
            // is the menu bar height (plus maybe the dock if it's on top).
            return screenFrame.height - visibleFrame.height
        }
    ```
  - Fixed weird off hover issue with the notch

</details>

---

#### August 11th 2025

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/142a8f3"><code>142a8f3</code></a></summary>

  - Cleaned up print statements
  - had a crash happen in the display settings, so I made sure im not force unwrapping anything
  - Made sure that the notch when closing will not show anything while closing, there was a weird timing issue
  - Changed the quickAccessWidgetDistanceFromTop from 4 to 0
  - Made sure that the Open Notch Content Dimension values are legit
    - This means that the spacing when open for the TopNotchView is now 0, so the full control is left up the the setting
    - Made sure that the setting for the quickAccessWidgetDistanceFromTop max is the maxNotchHeight

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/da3acd4"><code>da3acd4</code></a></summary>
    
  - Completely got rid of the touch settings, and replaced it for a context menu, so right click can be used for lots of other things
    - Belive cuz of this i broke UI Tests, so gonna have to fix that

</details>

---

#### August 24th 2025
<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/f674691"><code>f674691</code></a></summary>

  - Added back a new HoverView, that is much more reliable and more accurate

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/d3c3d28"><code>d3c3d28</code></a></summary>

  - Removed lots of unused code
  - Renamed Hover Album Target from "Album Image Only" to "Album Image"
  - Cleaned alot of AppDelegate replaced with AppCoordinator that handles all the logic
  - Added New Window Coordinator to handle all the window logic
    - This made sure that we can get rid of WindowGroup {} in the main App file and have more control over the windows
    - Fixed bug in QR Code For Filetray where it wasnt catching SettingsModel at runtime
  - SettingsCoordinator to handle the settings window logic, this uses the WindowCoordinator
  - Made sure everything flows through the SettingsCoordinator to open the settings window
  - Main File is much cleaner now, added new destroyViewWindow function to close the window of the assigned view
  - New Debug File, just moved things over from the main app file
  - Moved Files around to make more sense

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/97e13dc"><code>97e13dc</code></a></summary>

  - Fixed a werid bug in the settings page background where it was rounded on the edges
  - New Proximity Width and Height Settings
    - This is nice cuz now we can visualize how the proximity area looks like

</details>

---

#### August 25th 2025
<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/d3c3d28"><code>d3c3d28</code></a></summary>

  - Fixing weird bug where the settings page wouldnt be focused when opened
    - Now we have a number of tries we can have the window be focused
  - Removed unused code
</details>

---

#### August 26th 2025
<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/ebbe428"><code>ebbe428</code></a></summary>

  - Moves Files around to make more sense
  - Fixed weird Metal Animations description, now is more clear and not in a awkward place
  - Reworked full Settings Container and Settings Sections, now is using more apple native things

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/6c23857"><code>6c23857</code></a></summary>

  - License Tab wouldnt let us scroll all the way to the bottom, so I fixed that

</details>

<details>
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/"><code></code></a></summary>

  - Fixed bug in WindowCoordinator where if we opened the settings window the first time, it wouldnt trigger the onOpen
  - Cleaning up ScrollUp - I thought threads were started and never stopped, but turns out Xcode is just tweaking, `Apple Fix Xcode`

</details>

---

#### References
  - ["Sick Ass Header Implementation"](https://github.com/NUIKit/CGSInternal/blob/master/CGSSpace.h)
