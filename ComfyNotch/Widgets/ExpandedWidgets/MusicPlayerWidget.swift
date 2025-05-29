import AppKit
import SwiftUI
import Combine
import SVGView


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
    
    @StateObject private var model = MusicPlayerWidgetModel.shared
    @StateObject private var settings = SettingsModel.shared
    
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
        .onAppear {
//            debugLog("Bundle Path: \(Bundle.main.bundlePath)")
        }
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
                        .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
                        .frame(width: max(CGFloat(model.nowPlayingInfo.positionSeconds / max(model.nowPlayingInfo.durationSeconds,1)) * geometry.size.width, 0), height: 4)
                        .cornerRadius(2)
                    
                    // Thumb
                    Circle()
                        .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
                        .frame(width: 12, height: 12)
                        .offset(x: max(CGFloat(model.nowPlayingInfo.positionSeconds / max(model.nowPlayingInfo.durationSeconds, 1)) * geometry.size.width - 6, -6))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Set the dragging flag to true
                            model.isDragging = true
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                            model.nowPlayingInfo.positionSeconds = Double(percentage) * model.nowPlayingInfo.durationSeconds
                        }
                        .onEnded { value in
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)

                            // Convert % ➜ absolute seconds
                            let newTimeInSeconds = percentage * model.nowPlayingInfo.durationSeconds

                            // 1. Seek the real player
                            AudioManager.shared.playAtTime(to: newTimeInSeconds)

                            // 2. Keep the thumb where the user left it (UI won’t flash back)
                            model.nowPlayingInfo.positionSeconds = newTimeInSeconds

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
                Text(formatDuration(model.nowPlayingInfo.positionSeconds))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDuration(model.nowPlayingInfo.durationSeconds))
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
        Text(model.nowPlayingInfo.trackName)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(1)
        Text(model.nowPlayingInfo.artistName)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.white)
            .lineLimit(1)
        Text(model.nowPlayingInfo.albumName)
            .font(.system(size: 11, weight: .light))
            .foregroundColor(.white)
            .lineLimit(1)
    }

    @ViewBuilder
    func renderAlbumCover() -> some View {
        ZStack(alignment: .topLeading) {
            if let artwork = model.nowPlayingInfo.artworkImage {
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
            if settings.showMusicProvider {
                Group {
                    /// Music Provider
                    switch model.nowPlayingInfo.musicProvider {
                    case .apple_music:
                        if let url = Bundle.main.url(forResource: "apple_music", withExtension: "svg", subdirectory: "Assets") {
                            Button(action: AudioManager.shared.openProvider ) {
                                SVGView(contentsOf: url)
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    case .spotify:
                        if let url = Bundle.main.url(forResource: "spotify", withExtension: "svg", subdirectory: "Assets") {
                            Button(action: AudioManager.shared.openProvider) {
                                SVGView(contentsOf: url)
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    case .none: EmptyView()
                    }
                }
            }
        }
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class MusicPlayerWidgetModel: ObservableObject {
    static let shared = MusicPlayerWidgetModel()
    
    @ObservedObject var nowPlayingInfo = AudioManager.shared.nowPlayingInfo
    @Published var isDragging: Bool = false
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        nowPlayingInfo.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send() // Force view update
            }
            .store(in: &cancellables)
    }
}
