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
                    renderSongMusicControls()
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture().onChanged { _ in }
            .onEnded { _ in }
            .exclusively(before: DragGesture())
        )
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
            .padding(.top, 3.5)
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
                .frame(width: 85, height: 85)
                .cornerRadius(8)
                .padding(.leading, 7.5)
                .padding(.top, 7.5)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .cornerRadius(8)
                .padding(.leading, 7.5)
                .frame(width: 85, height: 85)
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
