import AppKit
import SwiftUI
import Combine


struct MusicPlayerWidget_: View, SwiftUIWidget {
    var name: String = "MusicPlayerWidget"
    @StateObject private var model = MusicPlayerWidgetModel()
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Album artwork
            if let artwork = model.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 85, height: 85)
                    .cornerRadius(8)
                    .padding(.leading, 7.5)
                    .padding(.top, 7.5)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 85, height: 85)
                    .cornerRadius(8)
                    .padding(.leading, 7.5)
                    .padding(.top, 7.5)
                    .allowsHitTesting(false)
            }
            
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(model.songText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.top, 3.5)
                
                Text(model.artistText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(model.albumText)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 5) {
                    Spacer()
                    
                    Button(action: {
                        AudioManager.shared.playPreviousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        AudioManager.shared.togglePlayPause()
                    }) {
                        Image(systemName: "playpause.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        AudioManager.shared.playNextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 5)
            }
            .padding(.trailing, 5)
        }
        .frame(width: 200, height: 100)
        .background(Color.black.opacity(0.01)) // Nearly transparent but allows interaction
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray, lineWidth: 1.5)
                .allowsHitTesting(false)
        )
        .cornerRadius(12)
        .gesture(
            DragGesture().onChanged { _ in }
            .onEnded { _ in }
            .exclusively(before: DragGesture())
        )
    }
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class MusicPlayerWidgetModel : ObservableObject {
    @Published var songText: String = AudioManager.shared.currentSongText
    @Published var artistText: String = AudioManager.shared.currentArtistText
    @Published var albumText: String = AudioManager.shared.currentAlbumText
    @Published var artworkImage: NSImage? = AudioManager.shared.currentArtworkImage

    private var cancellables = Set<AnyCancellable>()

    init() {
        AudioManager.shared.$currentSongText
            .receive(on: RunLoop.main)
            .sink { [weak self] newSong in
                self?.songText = newSong
            }
            .store(in: &cancellables)

        AudioManager.shared.$currentArtistText
            .receive(on: RunLoop.main)
            .sink { [weak self] newArtist in
                self?.artistText = newArtist
            }
            .store(in: &cancellables)

        AudioManager.shared.$currentAlbumText
            .receive(on: RunLoop.main)
            .sink { [weak self] newAlbum in
                self?.albumText = newAlbum
            }
            .store(in: &cancellables)

        AudioManager.shared.$currentArtworkImage
            .receive(on: RunLoop.main)
            .sink { [weak self] newImage in
                self?.artworkImage = newImage
            }
            .store(in: &cancellables)
    }
}

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

            // album art pinned to top
            albumArtImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 7.5),
            // album art pinned to left
            albumArtImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 7.5),
            albumArtImage.widthAnchor.constraint(equalToConstant: 85),
            albumArtImage.heightAnchor.constraint(equalToConstant: 85),

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
            nextButton.topAnchor.constraint(equalTo: albumLabel.bottomAnchor, constant: 10),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2), // Was -5, now -2
            nextButton.widthAnchor.constraint(equalToConstant: 30),
            nextButton.heightAnchor.constraint(equalToConstant: 30),

            // Play/Pause button, with less spacing:
            playPauseButton.topAnchor.constraint(equalTo: albumLabel.bottomAnchor, constant: 10),
            playPauseButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -5), // Was -10, now -5
            playPauseButton.widthAnchor.constraint(equalToConstant: 30),
            playPauseButton.heightAnchor.constraint(equalToConstant: 30),

            // Previous button, similarly adjusted:
            previousButton.topAnchor.constraint(equalTo: albumLabel.bottomAnchor, constant: 10),
            previousButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -5), // Was -10, now -5
            previousButton.widthAnchor.constraint(equalToConstant: 30),
            previousButton.heightAnchor.constraint(equalToConstant: 30)
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