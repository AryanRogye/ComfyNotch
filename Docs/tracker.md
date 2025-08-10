#### August 8th 2025

<details>
  <summary> View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/2ea1cbb"><code>2ea1cbb</code></a> </summary>

  - Added back re_align_notch into new implimentation of the notch 
  - Added back HUD Live Activities into the notch
  - Added a Space Manager 

</details>

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
    <summary>View Changes | <a href="https://github.com/aryanrogye/ComfyNotch/commit/"><code>coming soon</code></a></summary>

  - Fixing mini Issues with the scroll manager
    - when hovering and oepning shows unnecessary fadeaway aniations
    - when closing would close then readjust the notch if music was playing, but now we flow into it
    - Thinking about new logic for the whole animation, where I wouldnt have to think much about it


</details>


#### References
  - ["Sick Ass Header Implimentation"](https://github.com/NUIKit/CGSInternal/blob/master/CGSSpace.h)
