
import AppKit
import MediaPlayer
import CoreAudio
import Foundation


enum PanelState {
    case CLOSED
    case PARTIALLY_OPEN
    case OPEN
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var panel_state : PanelState = .CLOSED

    var minPanelHeight: CGFloat = 40
    var maxPanelHeight: CGFloat = 100

    var minPanelWidth: CGFloat = 300
    var maxPanelWidth: CGFloat = 400

    var startPanelHeight: CGFloat = 40
    var startPanelWidth: CGFloat = 300

    var padding: CGFloat = 15

    // text for the current song or "Nothing Currently Playing"
    var currentSongText: String = "Nothing Currently Playing"
    var currentSongTextField: NSTextField!

    // 4 buttons, previous, next, play/pause
    // only 3 show
    var previousButton: NSButton!
    var nextButton: NSButton!
    var playPauseButton: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.start();
    }

    func start() -> Void {
        setupFrame()
        setupSongInfoTimer()

        // Register for two-finger scroll events
        // Global monitor for events outside your app
        NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
            if self.isMouseInPanelRegion() {
                self.handleTwoFingerScroll(event)
            }
        }
    
        // Local monitor for events inside your app
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if self.isMouseInPanelRegion() {
                self.handleTwoFingerScroll(event)
            }
            return event
        }
    }

    func setupFrame() {
        guard let screen = NSScreen.main else { return }
        // Full screen, not visibleFrame
        let screenFrame = screen.frame

        let panelRect = NSRect(
            // Position it near the top of the screen
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - startPanelHeight - 2,
            width: startPanelWidth,
            height: startPanelHeight 
        )

        panel = NSPanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],  // Completely frameless
            backing: .buffered,
            defer: false
        )

        panel.title = "ComfyNotch"
        panel.level = .screenSaver  // Stays visible even over fullscreen apps
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .black.withAlphaComponent(0.7)
        panel.ignoresMouseEvents = false  // Allow interaction
        panel.hasShadow = false  // Remove shadow to make it seamless



        panel.makeKeyAndOrderFront(nil)
    }

    func addButtons() {
        previousButton = NSButton(title: "⏮️", target: self, action: #selector(previousButtonTapped))
        nextButton = NSButton(title: "⏭️", target: self, action: #selector(nextButtonTapped))
        playPauseButton = NSButton(title: "⏯️", target: self, action: #selector(playPauseButtonTapped))

        previousButton.frame = NSRect(x: 30, y: 5, width: 60, height: 30)
        playPauseButton.frame = NSRect(x: 100, y: 5, width: 60, height: 30)
        nextButton.frame = NSRect(x: 170, y: 5, width: 60, height: 30)

        panel.contentView?.addSubview(previousButton)
        panel.contentView?.addSubview(nextButton)
        panel.contentView?.addSubview(playPauseButton)

        currentSongTextField = NSTextField(labelWithString: currentSongText)
        currentSongTextField.frame = NSRect(x: 250, y: 5, width: 300, height: 30)
        currentSongTextField.isEditable = false
        currentSongTextField.isBordered = false
        currentSongTextField.backgroundColor = .clear
        currentSongTextField.textColor = .white
        panel.contentView?.addSubview(currentSongTextField)
    }

    @objc func previousButtonTapped() {
    }

    @objc func nextButtonTapped() {
    }

    @objc func playPauseButtonTapped() {
    }

    func runAppleScript(script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }

    func setupSongInfoTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCurrentSongInfo()
        }
    }

    func updateCurrentSongInfo() {
        DispatchQueue.global(qos: .background).async {
        }
    }

    func handleTwoFingerScroll(_ event: NSEvent) {
        let scrollDeltaY = event.scrollingDeltaY

        // Calculate new height
        let newHeight = panel.frame.height + scrollDeltaY
        let clampedHeight = max(minPanelHeight, min(maxPanelHeight, newHeight))
    
        // Calculate new width proportionally to height change
        let heightPercentage = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)
        let newWidth = minPanelWidth + (heightPercentage * (maxPanelWidth - minPanelWidth))
    
        // Apply clamping to width
        let clampedWidth = max(minPanelWidth, min(maxPanelWidth, newWidth))

        // Update the panel's size smoothly
        updatePanelSize(toHeight: clampedHeight, toWidth: clampedWidth)
        updatePanelState(for: clampedHeight)
    }

    func hideButtons() {
        previousButton?.isHidden = true
        nextButton?.isHidden = true
        playPauseButton?.isHidden = true
        currentSongTextField?.isHidden = true
    }

    func showButtons() {
        if previousButton == nil {
            addButtons()
        }
        previousButton.isHidden = false
        nextButton.isHidden = false
        playPauseButton.isHidden = false
        currentSongTextField.isHidden = false
    }

    func updatePanelState(for height: CGFloat) {
        if height >= maxPanelHeight {
            panel_state = .OPEN
            showButtons()
        } else if height <= minPanelHeight {
            panel_state = .CLOSED
            hideButtons()
        } else {
            panel_state = .PARTIALLY_OPEN
            hideButtons()
        }
    }

    func updatePanelSize(toHeight newHeight: CGFloat, toWidth newWidth: CGFloat) {
        guard let screen = NSScreen.main else { return }

        var panelFrame = panel.frame
        panelFrame.origin.y = screen.frame.height - newHeight - 2
        panelFrame.size.height = newHeight
        panelFrame.size.width = newWidth
        panelFrame.origin.x = (screen.frame.width - newWidth) / 2

        panel.setFrame(panelFrame, display: true, animate: true)
    }

    func isMouseInPanelRegion() -> Bool {
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        
        // Create a simple rectangular detection area exactly matching the panel
        // plus some padding around all sides
        let paddedFrame = NSRect(
            x: panel.frame.origin.x - padding,
            y: panel.frame.origin.y - padding,
            width: panel.frame.width + (padding * 2),
            height: panel.frame.height + (padding * 2)
        )
        
        return paddedFrame.contains(mouseLocation)
    }

    /** 
     *
     * Get the current song playing in any media player (iTunes, Spotify, etc.)
     * will return "Nothing Currently Playing" if no song is playing but if theres a
     * error it will return "Error: \(error)"
     *
     **/
    func isAudioPlaying(completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var propertySize: UInt32 = 0
            let result = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize)
            
            if result != noErr {
                DispatchQueue.main.async {
                    completion("Error: Unable to fetch audio devices.")
                }
                return
            }
            
            let numberOfDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
            var devices = [AudioDeviceID](repeating: 0, count: numberOfDevices)
            
            let result2 = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propertySize, &devices)
            
            if result2 != noErr {
                DispatchQueue.main.async {
                    completion("Error: Unable to fetch device list.")
                }
                return
            }
            
            for device in devices {
                var volume: Float32 = 0
                var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))
                
                var inputAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioObjectPropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                let status = AudioObjectGetPropertyData(device, &inputAddress, 0, nil, &volumeSize, &volume)
                
                if status == noErr && volume > 0.0 {
                    DispatchQueue.main.async {
                        completion("Something is playing 🎵")
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion("Nothing Currently Playing 🚫")
            }
        }
    }
}