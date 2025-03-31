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
    var currentSongNameText: String = "Nothing Currently Playing"
    var currentArtistText: String = "Unknown Artist"
    var currentAlbumText: String = "Unknown Album"

    var currentSongNameTextField: NSTextField!
    var currentArtistTextField: NSTextField!
    var currentAlbumTextField: NSTextField!

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

    var musicInfoView: NSView!

    let buttonWidth: CGFloat = 20
    let buttonHeight: CGFloat = 20
    let buttonSpacing: CGFloat = 10

    
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
        panel.backgroundColor = .black.withAlphaComponent(0.9)
        panel.ignoresMouseEvents = false  // Allow interaction
        panel.hasShadow = false  // Remove shadow to make it seamless

        setupAlbumArtImage()
        setupMusicInfoView()

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

    func setupMusicInfoView() {
        musicInfoView = NSView()
        musicInfoView.translatesAutoresizingMaskIntoConstraints = false
        musicInfoView.isHidden = true // Start hidden (only show when OPEN)

        panel.contentView?.addSubview(musicInfoView)

        // Update the text values from AudioManager
        currentSongNameText = AudioManager.shared.currentSongText
        currentArtistText = AudioManager.shared.currentArtistText
        currentAlbumText = AudioManager.shared.currentAlbumText

        currentSongNameTextField = NSTextField(labelWithString: currentSongNameText)
        currentArtistTextField = NSTextField(labelWithString: currentArtistText)
        currentAlbumTextField = NSTextField(labelWithString: currentAlbumText)
        
        // More visible styling for the song title
        currentSongNameTextField.font = NSFont.boldSystemFont(ofSize: 12)
        
        // Style for artist and album
        currentArtistTextField.font = NSFont.systemFont(ofSize: 11)
        currentAlbumTextField.font = NSFont.systemFont(ofSize: 11)
        currentAlbumTextField.textColor = NSColor.lightGray
        currentArtistTextField.textColor = NSColor.lightGray
        
        [currentSongNameTextField, currentArtistTextField, currentAlbumTextField].forEach { label in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            label.lineBreakMode = .byTruncatingTail
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            musicInfoView.addSubview(label)
        }

        // Add Buttons to musicInfoView
        addButtons(to: musicInfoView)


        // Position the musicInfoView to the right of the album art with some spacing
        NSLayoutConstraint.activate([
            // pushes to the right of the album art
            musicInfoView.leadingAnchor.constraint(equalTo: albumArtImage.trailingAnchor, constant: 6),
            // bringing it closer to the top
            musicInfoView.centerYAnchor.constraint(equalTo: albumArtImage.centerYAnchor, constant: -5),

            // Increase width constraint to give more space for text
            musicInfoView.widthAnchor.constraint(greaterThanOrEqualToConstant: 125),

            // Allow it to expand towards the right edge of the panel
            musicInfoView.trailingAnchor.constraint(lessThanOrEqualTo: panel.contentView!.trailingAnchor, constant: -15)
        ])

        // Position the text fields within the musicInfoView
        NSLayoutConstraint.activate([
            // Song title at the top
            currentSongNameTextField.topAnchor.constraint(equalTo: musicInfoView.topAnchor),
            currentSongNameTextField.leadingAnchor.constraint(equalTo: musicInfoView.leadingAnchor),
            currentSongNameTextField.trailingAnchor.constraint(equalTo: musicInfoView.trailingAnchor),
            currentSongNameTextField.heightAnchor.constraint(equalToConstant: 16), // Explicit height
    
            // Album in the middle
            currentAlbumTextField.topAnchor.constraint(equalTo: currentSongNameTextField.bottomAnchor, constant: 4),
            currentAlbumTextField.leadingAnchor.constraint(equalTo: musicInfoView.leadingAnchor),
            currentAlbumTextField.trailingAnchor.constraint(equalTo: musicInfoView.trailingAnchor),
            currentAlbumTextField.heightAnchor.constraint(equalToConstant: 14), // Explicit height
    
            // Artist at the bottom
            currentArtistTextField.topAnchor.constraint(equalTo: currentAlbumTextField.bottomAnchor, constant: 4),
            currentArtistTextField.leadingAnchor.constraint(equalTo: musicInfoView.leadingAnchor),
            currentArtistTextField.trailingAnchor.constraint(equalTo: musicInfoView.trailingAnchor),
            currentArtistTextField.heightAnchor.constraint(equalToConstant: 14), // Explicit height
            // currentArtistTextField.bottomAnchor.constraint(equalTo: musicInfoView.bottomAnchor)
        ])
    }

    func addButtons(to parentView: NSView) {

        previousButton = createStyledButton(symbolName: "backward.fill", action: #selector(previousButtonTapped))
        playPauseButton = createStyledButton(symbolName: "playpause.fill", action: #selector(playPauseButtonTapped))
        nextButton = createStyledButton(symbolName: "forward.fill", action: #selector(nextButtonTapped))
        
        [previousButton, playPauseButton, nextButton].forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            parentView.addSubview(button)
        }

        NSLayoutConstraint.activate([
            previousButton.topAnchor.constraint(equalTo: currentArtistTextField.bottomAnchor, constant: 5),
            previousButton.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            previousButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            previousButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -5), // Add padding at the bottom


            playPauseButton.topAnchor.constraint(equalTo: currentArtistTextField.bottomAnchor, constant: 5),
            playPauseButton.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: buttonSpacing),
            playPauseButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            playPauseButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            playPauseButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -5),


            nextButton.topAnchor.constraint(equalTo: currentArtistTextField.bottomAnchor, constant: 5),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: buttonSpacing),
            nextButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            nextButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            nextButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -5),

        ])
    }

    func createStyledButton(symbolName: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        button.target = self
        button.action = action
        button.wantsLayer = true
        button.isBordered = false
        button.layer?.cornerRadius = 8
        button.contentTintColor = .white
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.image?.size = NSSize(width: 10, height: 10) // Adjust as needed
        button.isEnabled = true
        button.setButtonType(.momentaryPushIn)

        return button
    }


    func showAlbumArtAtOpenPosition() {
        // Deactivate Closed Constraints
        albumArtClosedXConstraint.isActive = false
        albumArtClosedYConstraint.isActive = false

        // Activate Open Constraints
        albumArtOpenXConstraint.isActive = true
        albumArtOpenYConstraint.isActive = true

        self.updateAlbumArtConstraints(isOpen: true)
        // Show the music info view when the panel is open
        musicInfoView.isHidden = false

        currentSongNameTextField.stringValue = AudioManager.shared.currentSongText
        currentArtistTextField.stringValue = AudioManager.shared.currentArtistText
        currentAlbumTextField.stringValue = AudioManager.shared.currentAlbumText

    }

    func showAlbumArtAtClosedPosition() {
        // Deactivate Open Constraints
        albumArtOpenXConstraint.isActive = false
        albumArtOpenYConstraint.isActive = false

        // Activate Closed Constraints
        albumArtClosedXConstraint.isActive = true
        albumArtClosedYConstraint.isActive = true

        self.updateAlbumArtConstraints(isOpen: false)
        // Hide the music info view when the panel is closed
        musicInfoView.isHidden = true
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
        previousButton.isHidden = false
        nextButton.isHidden = false
        playPauseButton.isHidden = false

        currentSongNameTextField.isHidden = false
        currentAlbumTextField.isHidden = false
        currentArtistTextField.isHidden = false
    }

    func hideButtons() {
        previousButton?.isHidden = true
        nextButton?.isHidden = true
        playPauseButton?.isHidden = true

        currentSongNameTextField?.isHidden = true
        currentAlbumTextField?.isHidden = true
        currentArtistTextField?.isHidden = true
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