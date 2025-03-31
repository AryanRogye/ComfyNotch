import AppKit


enum PanelState {
    case CLOSED
    case PARTIALLY_OPEN
    case OPEN
}

class UIManager {
    static let shared = UIManager()
    
    var panel: NSPanel!
    var panel_state : PanelState = .CLOSED


    var startPanelHeight: CGFloat = 0
    var startPanelWidth: CGFloat = 300

    // Buttons 
    var currentSongText: String = "Nothing Currently Playing"
    var currentSongTextField: NSTextField!

    // 4 buttons, previous, next, play/pause
    // only 3 show
    var previousButton: NSButton!
    var nextButton: NSButton!
    var playPauseButton: NSButton!

    var albumArtImage: NSImageView!

    var albumArtClosedXConstraint: NSLayoutConstraint!
    var albumArtClosedYConstraint: NSLayoutConstraint!

    var albumArtOpenXConstraint: NSLayoutConstraint!
    var albumArtOpenYConstraint: NSLayoutConstraint!

    var albumArtWidthConstraint: NSLayoutConstraint!
    var albumArtHeightConstraint: NSLayoutConstraint!



    
    private init() {
        startPanelHeight = getNotchHeight()
        AudioManager.shared.getNowPlayingInfo()
    }

    func setupFrame() {
        guard let screen = NSScreen.main else { return }
        // Full screen, not visibleFrame
        let screenFrame = screen.frame
        let notchHeight = getNotchHeight()

        let panelRect = NSRect(
            // Position it near the top of the screen
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - startPanelHeight - 2,
            width: startPanelWidth,
            height: notchHeight 
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
        panel.backgroundColor = .yellow.withAlphaComponent(1)
        panel.ignoresMouseEvents = false  // Allow interaction
        panel.hasShadow = false  // Remove shadow to make it seamless

        setupAlbumArtImage()

        panel.makeKeyAndOrderFront(nil)
    }

    func getNotchHeight() -> CGFloat {
        if let screen = NSScreen.main {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.top
        }
        return 0
    }

    func setupAlbumArtImage() {
        albumArtImage = NSImageView()
        albumArtImage.translatesAutoresizingMaskIntoConstraints = false
        albumArtImage.imageScaling = .scaleProportionallyUpOrDown
        albumArtImage.isHidden = false // Keep it visible
    
        panel.contentView?.addSubview(albumArtImage)
    
        // Closed State Position (Left side, closer to the notch)
        albumArtClosedXConstraint = albumArtImage.leadingAnchor.constraint(
            equalTo: panel.contentView!.leadingAnchor, 
            constant: 10
        )
        albumArtClosedYConstraint = albumArtImage.topAnchor.constraint(
            equalTo: panel.contentView!.topAnchor, 
            constant: 3.5
        )

        // Open State Position
        albumArtOpenXConstraint = albumArtImage.leadingAnchor.constraint(
            equalTo: panel.contentView!.leadingAnchor,
            constant: 5
        )
        albumArtOpenYConstraint = albumArtImage.centerYAnchor.constraint(
            equalTo: panel.contentView!.centerYAnchor
        )

        // SIZE
        albumArtWidthConstraint = albumArtImage.widthAnchor.constraint(
            equalToConstant: 30
        )
        albumArtHeightConstraint = albumArtImage.heightAnchor.constraint(
            equalToConstant: getNotchHeight() - 10
        )

    
        NSLayoutConstraint.activate([
            albumArtClosedXConstraint, // Start with this active
            albumArtClosedYConstraint,
            albumArtWidthConstraint,
            albumArtHeightConstraint
        ])
    }

    func hideButtons() {
        previousButton?.isHidden = true
        nextButton?.isHidden = true
        playPauseButton?.isHidden = true
        currentSongTextField?.isHidden = true
    }

    func showAlbumArtAtOpenPosition() {
        // Deactivate Closed Constraints
        albumArtClosedXConstraint.isActive = false
        albumArtClosedYConstraint.isActive = false

        // Activate Open Constraints
        albumArtOpenXConstraint.isActive = true
        albumArtOpenYConstraint.isActive = true

        self.updateAlbumArtConstraints(isOpen: true)
    }

    func showAlbumArtAtClosedPosition() {
        // Deactivate Open Constraints
        albumArtOpenXConstraint.isActive = false
        albumArtOpenYConstraint.isActive = false

        // Activate Closed Constraints
        albumArtClosedXConstraint.isActive = true
        albumArtClosedYConstraint.isActive = true

        self.updateAlbumArtConstraints(isOpen: false)
    }

    func updateAlbumArtConstraints(isOpen: Bool) {
        if isOpen {
            // Make it bigger when open
            albumArtWidthConstraint.constant = 90 
            albumArtHeightConstraint.constant = 90
        } else {
            // Keep it small when closed
            albumArtWidthConstraint.constant = 30
            albumArtHeightConstraint.constant = getNotchHeight() - 10
        }
        
        // Animate the changes for smooth transition
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            panel.contentView?.animator().layoutSubtreeIfNeeded()
        }
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

    func addButtons() {
        let panelWidth = panel.frame.width
        // Remove previous UI components if they exist
        currentSongTextField?.removeFromSuperview()
        previousButton?.removeFromSuperview()
        playPauseButton?.removeFromSuperview()
        nextButton?.removeFromSuperview()

        // Song Title / Artist Name Label
        currentSongTextField = NSTextField(labelWithString: AudioManager.shared.currentSongText)
        currentSongTextField.frame = NSRect(
            x: 0,
            y: 30, // Slightly higher to make space for buttons below
            width: panelWidth,
            height: 30
        )
        currentSongTextField.alignment = .center
        currentSongTextField.isEditable = false
        currentSongTextField.isBordered = false
        currentSongTextField.backgroundColor = .clear
        currentSongTextField.textColor = .white
        panel.contentView?.addSubview(currentSongTextField)

        // Button Sizes and Spacing
        let buttonWidth: CGFloat = 40
        let buttonHeight: CGFloat = 30
        let buttonSpacing: CGFloat = 20
        
        let totalButtonWidth = (buttonWidth * 3) + (buttonSpacing * 2)
        let buttonOriginX = (panelWidth - totalButtonWidth) / 2
        let buttonOriginY: CGFloat = 10  // Space between label and buttons

        // Previous Button
        previousButton = NSButton(title: "⏮️", target: self, action: #selector(previousButtonTapped))
        previousButton.frame = NSRect(x: buttonOriginX, y: buttonOriginY, width: buttonWidth, height: buttonHeight)
        panel.contentView?.addSubview(previousButton)

        // Play/Pause Button
        playPauseButton = NSButton(title: "⏯️", target: self, action: #selector(playPauseButtonTapped))
        playPauseButton.frame = NSRect(x: buttonOriginX + buttonWidth + buttonSpacing, y: buttonOriginY, width: buttonWidth, height: buttonHeight)
        panel.contentView?.addSubview(playPauseButton)

        // Next Button
        nextButton = NSButton(title: "⏭️", target: self, action: #selector(nextButtonTapped))
        nextButton.frame = NSRect(x: buttonOriginX + (buttonWidth + buttonSpacing) * 2, y: buttonOriginY, width: buttonWidth, height: buttonHeight)
        panel.contentView?.addSubview(nextButton)
    }


    @objc private func previousButtonTapped() {
        AudioManager.shared.playPreviousTrack()
    }

    @objc private func nextButtonTapped() {
        AudioManager.shared.playNextTrack()
    }

    @objc private func playPauseButtonTapped() {
        AudioManager.shared.togglePlayPause()
    }

}