import AppKit

class MusicPlayerWidget : Widget {
    var name : String = "MusicPlayerWidget"
    var view : NSView

    // Labels for song, artist, and album
    private var songLabel: NSTextField
    private var artistLabel: NSTextField
    private var albumLabel: NSTextField
    private var previousButton: NSButton
    private var playPauseButton: NSButton
    private var nextButton: NSButton
    
    private let buttonWidth: CGFloat = 20
    private let buttonHeight: CGFloat = 20
    private let buttonSpacing: CGFloat = 10

    private var albumArtImage: NSImageView!

    init() {
        view = NSView()
        view.isHidden = true
        view.wantsLayer = true
        view.layer?.borderWidth = 1.5
        view.layer?.borderColor = NSColor.darkGray.cgColor
        view.layer?.cornerRadius = 12

        songLabel = NSTextField(labelWithString: AudioManager.shared.currentSongText)
        songLabel.lineBreakMode = .byTruncatingTail
        songLabel.usesSingleLineMode = true
        songLabel.cell?.truncatesLastVisibleLine = true

        artistLabel = NSTextField(labelWithString: AudioManager.shared.currentArtistText)
        artistLabel.lineBreakMode = .byTruncatingTail
        artistLabel.usesSingleLineMode = true
        artistLabel.cell?.truncatesLastVisibleLine = true

        albumLabel = NSTextField(labelWithString: AudioManager.shared.currentAlbumText)
        albumLabel.lineBreakMode = .byTruncatingTail
        albumLabel.usesSingleLineMode = true
        albumLabel.cell?.truncatesLastVisibleLine = true

        // Need to do this to create buttons with symbols
        previousButton = NSButton()
        playPauseButton = NSButton()
        nextButton = NSButton()

        previousButton = createStyledButton(symbolName: "backward.fill", action: #selector(previousButtonTapped))
        playPauseButton = createStyledButton(symbolName: "playpause.fill", action: #selector(playPauseButtonTapped))
        nextButton = createStyledButton(symbolName: "forward.fill", action: #selector(nextButtonTapped))
        
        albumArtImage = NSImageView()
        albumArtImage.translatesAutoresizingMaskIntoConstraints = false
        albumArtImage.imageScaling = .scaleProportionallyUpOrDown
        albumArtImage.isHidden = false

        
        [songLabel, artistLabel, albumLabel, previousButton, playPauseButton, nextButton, albumArtImage].forEach { view.addSubview($0) }
        
        setupInternalConstraints()

        AudioManager.shared.onNowPlayingInfoUpdated = { [weak self] in
            self?.update()  // Trigger the update method whenever new info is available
        }
    }

    func update() {
        songLabel.stringValue = AudioManager.shared.currentSongText
        artistLabel.stringValue = AudioManager.shared.currentArtistText
        albumLabel.stringValue = AudioManager.shared.currentAlbumText
        albumArtImage.image = AudioManager.shared.currentArtworkImage
    }

    private func setupInternalConstraints() {
        songLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        albumLabel.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        albumArtImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Album art pinned to top left, fixed size
            albumArtImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 3.5),
            albumArtImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            albumArtImage.widthAnchor.constraint(equalToConstant: 90),
            albumArtImage.heightAnchor.constraint(equalToConstant: 90),

            // songLabel to the right of album art
            songLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 3.5),
            songLabel.leadingAnchor.constraint(equalTo: albumArtImage.trailingAnchor, constant: 10),
            songLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -5),

            // artistLabel below songLabel
            artistLabel.topAnchor.constraint(equalTo: songLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: albumArtImage.trailingAnchor, constant: 10),
            artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -5),

            // albumLabel below artistLabel
            albumLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 4),
            albumLabel.leadingAnchor.constraint(equalTo: albumArtImage.trailingAnchor, constant: 10),
            albumLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -5),

            // Buttons pinned below the album art (if you still want them)
            previousButton.topAnchor.constraint(equalTo: albumArtImage.bottomAnchor, constant: 5),
            previousButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            previousButton.heightAnchor.constraint(equalToConstant: 20),

            playPauseButton.topAnchor.constraint(equalTo: albumArtImage.bottomAnchor, constant: 5),
            playPauseButton.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: buttonSpacing),
            playPauseButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            playPauseButton.heightAnchor.constraint(equalToConstant: 20),

            nextButton.topAnchor.constraint(equalTo: albumArtImage.bottomAnchor, constant: 5),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: buttonSpacing),
            nextButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            nextButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
    
    private func createStyledButton(symbolName: String, action: Selector) -> NSButton {
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
        button.image?.size = NSSize(width: 10, height: 10)
        button.isEnabled = true
        button.setButtonType(.momentaryPushIn)

        return button
    }

    func show() {
        view.isHidden = false
    }

    func hide() {
        view.isHidden = true
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