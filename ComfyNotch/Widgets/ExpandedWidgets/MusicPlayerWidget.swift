import AppKit
import SwiftUI
import Combine
import SVGView

struct MusicControlButton: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        MusicControlButtonView(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
    
    struct MusicControlButtonView<Label: View>: View {
        @State private var isHovering = false
        let isPressed: Bool
        let label: () -> Label
        
        var body: some View {
            label()
                .frame(width: 30, height: 30)
                .opacity(isPressed ? 0.7 : 1.0)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isHovering ? 0.1 : 0.0))
                        .scaleEffect(isHovering ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                )
                .onHover { hovering in
                    isHovering = hovering
                }
        }
    }
}

struct MusicPlayerWidget: View, Widget {
    var name: String = "MusicPlayerWidget"
    var imageWidth: CGFloat = 120
    var imageHeight: CGFloat = 120
    
    @ObservedObject private var model = MusicPlayerWidgetModel.shared
    @ObservedObject private var settings = SettingsModel.shared
    
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
                let effectivePosition = model.isDragging ? model.manualDragPosition : model.nowPlayingInfo.positionSeconds
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress bar
                    Rectangle()
                        .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
                        .frame(width: max(CGFloat(effectivePosition / max(model.nowPlayingInfo.durationSeconds,1)) * geometry.size.width, 0), height: 4)
                        .cornerRadius(2)
                    
                    // Thumb
                    Circle()
                        .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
                        .frame(width: 12, height: 12)
                        .offset(x: max(CGFloat(effectivePosition / max(model.nowPlayingInfo.durationSeconds, 1)) * geometry.size.width - 6, -6))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Set the dragging flag to true
                            model.isDragging = true
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                            model.manualDragPosition = Double(percentage) * model.nowPlayingInfo.durationSeconds
                        }
                        .onEnded { value in
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                            
                            // Convert % ➜ absolute seconds
                            let newTimeInSeconds = percentage * model.nowPlayingInfo.durationSeconds
                            
                            // 1. Seek the real player
                            AudioManager.shared.playAtTime(to: newTimeInSeconds)
                            
                            // 2. Keep the thumb where the user left it (UI won’t flash back)
                            model.nowPlayingInfo.positionSeconds = newTimeInSeconds
                            model.manualDragPosition = newTimeInSeconds
                            
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
            .foregroundColor(.white.opacity(0.9))
            .lineLimit(1)
        Text(model.nowPlayingInfo.artistName)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.white.opacity(0.7))
            .lineLimit(1)
        Text(model.nowPlayingInfo.albumName)
            .font(.system(size: 11, weight: .light))
            .foregroundColor(.white.opacity(0.5))
            .lineLimit(1)
    }
    
    @ViewBuilder
    func renderAlbumCover() -> some View {
        ZStack(alignment: .bottomTrailing) {
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
                    if settings.musicController == .mediaRemote {
                        if settings.overridenMusicProvider == .apple_music {
                            appleMusicProvider
                        } else if settings.overridenMusicProvider == .spotify {
                            spotifyProvider
                        }
                    } else if settings.musicController == .spotify_music {
                        switch model.nowPlayingInfo.musicProvider {
                        case .apple_music:
                            appleMusicProvider
                        case .spotify:
                            spotifyProvider
                        case .none: EmptyView()
                        }
                    }
                    /// Music Provider
                }
            }
        }
    }
    
    struct HoverEffectWrapper<Content: View>: View {
        @State private var isHovering = false
        let content: () -> Content
        
        var body: some View {
            content()
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
                .onHover { hovering in
                    isHovering = hovering
                }
        }
    }
    
    private var spotifyProvider: some View {
        VStack {
            if let url = Bundle.main.url(forResource: "spotify", withExtension: "svg", subdirectory: "Assets") {
                Button(action: AudioManager.shared.openProvider) {
                    HoverEffectWrapper {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 24, height: 24)
                            SVGView(contentsOf: url)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .offset(x: 8, y: 8)
                    .zIndex(1)
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var appleMusicProvider: some View {
        VStack {
            if let url = Bundle.main.url(forResource: "apple_music", withExtension: "svg", subdirectory: "Assets") {
                Button(action: AudioManager.shared.openProvider ) {
                    HoverEffectWrapper {
                        SVGView(contentsOf: url)
                            .frame(width: 24, height: 24)
                    }
                    .offset(x: 8, y: 8)
                    .zIndex(1)
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
    @Published var manualDragPosition: Double = 0
    
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
