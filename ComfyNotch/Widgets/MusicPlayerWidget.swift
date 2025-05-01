import AppKit
import SwiftUI
import Combine


struct MusicControlButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Keep general modifiers
            .frame(width: 30, height: 30)
            .opacity(configuration.isPressed ? 0.7 : 1.0) // Add visual feedback for press
    }
}

struct MusicPlayerWidget: View, Widget {
    
    var name: String = "MusicPlayerWidget"
    var imageWidth: CGFloat = 120
    var imageHeight: CGFloat = 120
    
    @StateObject private var model = MusicPlayerWidgetModel()
    var body: some View {
        HStack(spacing: 10) {
            // Album artwork
            renderAlbumCover()
            // Song info
            VStack(alignment: .leading) {
                renderSongInformation()
                // Control buttons
                HStack(spacing: 5) {
                    renderCurrentSongPosition()
                }
                HStack(spacing: 5) {
                    renderSongMusicControls()
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func renderCurrentSongPosition() -> some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress bar
                    Rectangle()
                        .fill(Color(nsColor: model.dominantColor))
                        .frame(width: max(CGFloat(model.currentSecondsSong / max(model.currentSecondsSongDuration, 1)) * geometry.size.width, 0), height: 4)
                        .cornerRadius(2)
                    
                    // Thumb
                    Circle()
                        .fill(Color(nsColor: model.dominantColor))
                        .frame(width: 12, height: 12)
                        .offset(x: max(CGFloat(model.currentSecondsSong / max(model.currentSecondsSongDuration, 1)) * geometry.size.width - 6, -6))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Set the dragging flag to true
                            model.isDragging = true
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                            model.currentSecondsSong = Double(percentage) * model.currentSecondsSongDuration
                        }
                        .onEnded { value in
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)

                            // Convert % ➜ absolute seconds
                            let newTimeInSeconds = percentage * model.currentSecondsSongDuration

                            // 1. Seek the real player
                            AudioManager.shared.playAtTime(to: newTimeInSeconds)

                            // 2. Keep the thumb where the user left it (UI won’t flash back)
                            model.currentSecondsSong = newTimeInSeconds

                            // 3. Re-enable live updates after a brief grace period
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                model.isDragging = false
                            }
                        }
                )
            }
            .frame(height: 12)
            
            // Time labels
            HStack {
                Text(formatDuration(model.currentSecondsSong))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDuration(model.currentSecondsSongDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }    // Helper function to format seconds as "MM:SS"
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    @ViewBuilder
    func renderSongMusicControls() -> some View {
        Button(action: {
            AudioManager.shared.playPreviousTrack()
        }) {
            // Apply image-specific modifiers here
            Image(systemName: "backward.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(.white)
        }
        .buttonStyle(MusicControlButton()) // Apply custom style

        Button(action: {
            AudioManager.shared.togglePlayPause()
        }) {
            // Apply image-specific modifiers here
            Image(systemName: "playpause.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(.white)
        }
        .buttonStyle(MusicControlButton()) // Apply custom style

        Button(action: {
            AudioManager.shared.playNextTrack()
        }) {
            // Apply image-specific modifiers here
            Image(systemName: "forward.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(.white)
        }
        .buttonStyle(MusicControlButton()) // Apply custom style
    }

    @ViewBuilder
    func renderSongInformation() -> some View {
        Text(model.songText)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(1)
        Text(model.artistText)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.white)
            .lineLimit(1)
        Text(model.albumText)
            .font(.system(size: 11, weight: .light))
            .foregroundColor(.white)
            .lineLimit(1)
    }

    @ViewBuilder
    func renderAlbumCover() -> some View {
        if let artwork = model.artworkImage {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageWidth, height: imageHeight)
                .cornerRadius(8)
                .padding(.leading, 7.5)
                .padding(.top, 7.5)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .cornerRadius(8)
                .padding(.leading, 7.5)
                .frame(width: imageWidth, height: imageHeight)
                .allowsHitTesting(false)
                .padding(.top, 7.5)
        }
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class MusicPlayerWidgetModel: ObservableObject {
    @Published var songText: String = AudioManager.shared.currentSongText
    @Published var artistText: String = AudioManager.shared.currentArtistText
    @Published var albumText: String = AudioManager.shared.currentAlbumText
    @Published var artworkImage: NSImage? = AudioManager.shared.currentArtworkImage
    @Published var currentSecondsSong: Double = AudioManager.shared.currentSecondsSong
    @Published var currentSecondsSongDuration: Double = AudioManager.shared.totalSecondsSong
    @Published var isDragging: Bool = false
    @Published var dominantColor: NSColor = AudioManager.shared.dominantColor


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
        AudioManager.shared.$currentSecondsSong
            .receive(on: RunLoop.main)
            .sink { [weak self] newCurrentSecondsSong in
                guard let self = self else { return }
                if !self.isDragging {
                    self.currentSecondsSong = newCurrentSecondsSong
                }
            }
            .store(in: &cancellables)
        AudioManager.shared.$totalSecondsSong
            .receive(on: RunLoop.main)
            .sink { [weak self] newTotalSecondsSong in
                self?.currentSecondsSongDuration = newTotalSecondsSong
            }
            .store(in: &cancellables)
        AudioManager.shared.$dominantColor
            .receive(on: RunLoop.main)
            .sink { [weak self] newColor in
                self?.dominantColor = newColor
            }
            .store(in: &cancellables)
        
    }
}
