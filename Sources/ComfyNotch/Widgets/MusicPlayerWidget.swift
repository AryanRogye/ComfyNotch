import AppKit
import SwiftUI
import Combine
struct MusicPlayerWidget: View, Widget {
    var name: String = "MusicPlayerWidget"
    @StateObject private var model = MusicPlayerWidgetModel()
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Album artwork
            renderAlbumCover()
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                renderSongInformation()
                // Control buttons
                HStack(spacing: 5) {
                    renderSongMusicControls()
                }
                .padding(.vertical, 5)
            }
            .padding(.trailing, 5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture().onChanged { _ in }
            .onEnded { _ in }
            .exclusively(before: DragGesture())
        )
        .padding(.vertical, 5)
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    func renderSongMusicControls() -> some View {
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
                .padding(.vertical, 5)
                .frame(maxHeight: .infinity, alignment: .center)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 85, height: 85)
                .cornerRadius(8)
                .padding(.leading, 7.5)
                .padding(.vertical, 5)
                .frame(maxHeight: .infinity, alignment: .center)
                .allowsHitTesting(false)
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
