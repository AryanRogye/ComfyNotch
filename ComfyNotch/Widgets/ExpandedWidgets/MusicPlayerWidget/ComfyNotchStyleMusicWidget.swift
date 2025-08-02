//
//  ComfyNotchStyleMusicWidget.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI
import SVGView

struct ComfyNotchStyleMusicWidget: View {
    
    @ObservedObject private var model = MusicPlayerWidgetModel.shared
    @ObservedObject private var settings = SettingsModel.shared
    
    @State private var isVisible: Bool = true
    @State private var cardHover = false
    
    private let iconWidth: CGFloat = 14
    private let iconHeight: CGFloat = 15
    private let iconPadding: CGFloat = 30
    private let cardPadding: CGFloat = 20
    private let albumSize: CGFloat = 80
    private let controlButtonSize: CGFloat = 40
    private let smallControlButtonSize: CGFloat = 32
    
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if isVisible {
                // MARK: - Album View
                renderAlbumCover()
                    .padding(.bottom)
                    .frame(alignment: .leading)
                
                // MARK: - Song Information and Controls
                VStack(alignment: .leading, spacing: 0) {
                    /// name/artist/album
                    renderSongInformation()
                    
                    /// Slider
                    renderCurrentSongPosition()
                    
                    /// Button
                    renderSongMusicControls()
                }
                .padding(.leading, cardPadding/3)
                .frame(alignment: .leading)
            }
        }
        // MARK: - Card Styling
        .frame(maxWidth: givenSpace.w, maxHeight: givenSpace.h)
        .onAppear {
            isVisible = true
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }
        .onDisappear {
            isVisible = false
            model.isDragging = false
        }
    }
    
    
    // MARK: - Adjust Slider
    @ViewBuilder
    func renderCurrentSongPosition() -> some View {
        if isVisible {
            HStack(alignment: .center, spacing: 4) {
                
                Text(formatDuration(model.nowPlayingInfo.positionSeconds))
                    .font(.system(size: 8, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(spacing: 6) {
                    // Progress bar
                    ZStack {
                        GeometryReader { geometry in
                            let effectivePosition = model.isDragging ? model.manualDragPosition : model.nowPlayingInfo.positionSeconds
                            ZStack(alignment: .leading) {
                                // Background track
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 6)
                                    .cornerRadius(2)
                                
                                // Progress bar
                                Rectangle()
                                    .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
                                    .frame(width: max(CGFloat(effectivePosition / max(model.nowPlayingInfo.durationSeconds,1)) * geometry.size.width, 0), height: 4)
                                    .cornerRadius(2)
                                    .shadow(color: Color(nsColor: model.nowPlayingInfo.dominantColor).opacity(0.5), radius: 4, x: 0, y: 2)
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
                                        model.manualDragPosition = newTimeInSeconds
                                        
                                        /// This is delayed because someone like me plays spotify on my tv
                                        /// the device is seperate from the controller so updates for spotify
                                        /// take some time to propagate.
                                        checkPositionUpdate(targetPosition: newTimeInSeconds, attempts: 0)
                                    }
                            )
                        }
                    }
                    .frame(height: 6)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .padding(.horizontal, 8)
                
                // Time labels
                Text(formatDuration(model.nowPlayingInfo.durationSeconds))
                    .font(.system(size: 8, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
            }
        } else {
            EmptyView()
        }
    }
    
    // Helper function to format seconds as "MM:SS"
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func checkPositionUpdate(targetPosition: Double, attempts: Int) {
        let maxAttempts = 10
        let checkInterval = 0.5
        
        if attempts >= maxAttempts {
            // Give up and reset
            model.isDragging = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
            let currentDiff = abs(model.nowPlayingInfo.positionSeconds - targetPosition)
            
            if currentDiff < 1.0 { // Within 1 second tolerance
                model.isDragging = false
            } else {
                checkPositionUpdate(targetPosition: targetPosition, attempts: attempts + 1)
            }
        }
    }
    
    // MARK: - Music Controls
    
    @ViewBuilder
    func renderSongMusicControls() -> some View {
        HStack(spacing: 8) {
            Button(action: {
                AudioManager.shared.playPreviousTrack()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: "backward.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(.white)
            }
            .buttonStyle(MusicControlButton(size: iconPadding, tint: model.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Button(action: {
                AudioManager.shared.togglePlayPause()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: model.nowPlayingInfo.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(.white)
            }
            .buttonStyle(MusicControlButton(size: iconPadding, tint: model.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Button(action: {
                AudioManager.shared.playNextTrack()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: "forward.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(.white)
            }
            .buttonStyle(MusicControlButton(size: iconPadding, tint: model.nowPlayingInfo.dominantColor)) // Apply custom style
        }
    }

    // MARK: - Song Information
    @ViewBuilder
    func renderSongInformation() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                // Song title with better typography
                Text(model.nowPlayingInfo.trackName)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                // Artist name
                Text(model.nowPlayingInfo.artistName)
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(.gray.opacity(0.7))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Album Cover
    
    @ViewBuilder
    func renderAlbumCover() -> some View {
        if isVisible {
            ZStack(alignment: .bottomTrailing) {
                if let artwork = model.nowPlayingInfo.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: albumSize, height: albumSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    placeholderAlbumCover
                }
                if settings.showMusicProvider {
                    renderProviderIcon
                }
            }
            .padding(.leading, cardPadding/3)
        }
    }
    
    @State private var isHovering = false
    private var renderProviderIcon: some View {
        Group {
            if settings.musicController == .mediaRemote {
                if settings.overridenMusicProvider == .apple_music {
                    renderAppleMusicProvider()
                } else if settings.overridenMusicProvider == .spotify {
                    renderSpotifyProvider()
                }
            } else if settings.musicController == .spotify_music {
                switch model.nowPlayingInfo.musicProvider {
                case .apple_music:
                    renderAppleMusicProvider()
                case .spotify:
                    renderSpotifyProvider()
                case .none:
                    EmptyView()
                }
            }
        }
        .offset(x: 8, y: 8)
        .scaleEffect(isHovering ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    @ViewBuilder
    func renderSpotifyProvider() -> some View {
        if let url = Bundle.main.url(forResource: "spotify", withExtension: "svg", subdirectory: "Assets") {
            Button(action: AudioManager.shared.openProvider) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    SVGView(contentsOf: url)
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    func renderAppleMusicProvider() -> some View {
        if let url = Bundle.main.url(forResource: "apple_music", withExtension: "svg", subdirectory: "Assets") {
            Button(action: AudioManager.shared.openProvider) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    SVGView(contentsOf: url)
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var placeholderAlbumCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.4),
                            Color.gray.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Image(systemName: "music.note")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: albumSize, height: albumSize)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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
}
