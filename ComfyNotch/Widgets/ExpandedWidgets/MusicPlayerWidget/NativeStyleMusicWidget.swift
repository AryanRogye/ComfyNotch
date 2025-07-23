//
//  NativeStyleMusicWidget.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct NativeStyleMusicWidget: View {
    @State private var isVisible: Bool = true
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    @ObservedObject private var model = MusicPlayerWidgetModel.shared
    @ObservedObject private var settings = SettingsModel.shared
    
    private let albumSize: CGFloat = 40
    
    private let iconWidth: CGFloat = 14
    private let iconHeight: CGFloat = 15
    private let iconPadding: CGFloat = 30
    private var cardPadding: CGFloat = 8
    
    @State private var cachedArtwork: NSImage?
    @State private var flipRotation: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isVisible {
                // 3 Sections Top Middle Bottom
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        renderAlbumCover()
                    }
                    
                    VStack {
                        renderSongInformation()
                        Spacer()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        FancyMovingBars(applyNoPadding: true)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .frame(maxWidth: .infinity)
                
                HStack {
                    renderCurrentSongPosition()
                }
                .padding(.horizontal)
                
                HStack(alignment: .center) {
                    renderSongMusicControls()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
//        .border(Color.red)
        .onAppear {
            isVisible = true
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }
        .onChange(of: model.nowPlayingInfo.artworkImage) { _, newArtwork in
            print("Calleddddddddd")
            handleArtworkFlip(newArtwork: newArtwork)           // Standard smooth flip
            // handleArtworkFlipFast(newArtwork: newArtwork)       // Quick flip
            // handleArtworkFlipBouncy(newArtwork: newArtwork)     // Spring bounce
            // handleArtworkFlipContinuous(newArtwork: newArtwork) // Smooth continuous
            // handleArtworkFlipVertical(newArtwork: newArtwork)   // Vertical flip
        }
    }
    
    // MARK: - Album Cover with Flip Animation
    @ViewBuilder
    func renderAlbumCover() -> some View {
        if isVisible {
            ZStack(alignment: .leading) {
                ZStack {
                    // Front side (old/cached image) - visible at 0°
                    if let cachedArtwork = cachedArtwork {
                        Image(nsImage: cachedArtwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: albumSize, height: albumSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .opacity(abs(flipRotation.truncatingRemainder(dividingBy: 360)) > 90 && abs(flipRotation.truncatingRemainder(dividingBy: 360)) < 270 ? 0 : 1)
                    } else {
                        placeholderAlbumCover
                            .opacity(abs(flipRotation.truncatingRemainder(dividingBy: 360)) > 90 && abs(flipRotation.truncatingRemainder(dividingBy: 360)) < 270 ? 0 : 1)
                    }
                    
                    // Back side (new image) - visible at 180°
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
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Flip the back side
                            .opacity(abs(flipRotation.truncatingRemainder(dividingBy: 360)) > 90 && abs(flipRotation.truncatingRemainder(dividingBy: 360)) < 270 ? 1 : 0)
                    }
                }
                .rotation3DEffect(
                    .degrees(flipRotation),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                if settings.showMusicProvider {
                    // renderProviderIcon
                }
            }
            .onChange(of: model.nowPlayingInfo.artworkImage) { _, newArtwork in
                handleArtworkFlip(newArtwork: newArtwork)
            }
            .onAppear {
                // Cache the initial artwork
                cachedArtwork = model.nowPlayingInfo.artworkImage
            }
        }
    }
    
    // MARK: - Handle 180° Flip with Two-Sided Card
    private func handleArtworkFlip(newArtwork: NSImage?) {
        // Only flip if artwork actually changed
        guard cachedArtwork != newArtwork else { return }
        
        // Start the 180° flip (0° to 180°)
        withAnimation(.easeInOut(duration: 0.6)) {
            flipRotation = 180
        }
        
        // After flip completes, reset for next flip and update cache
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Reset rotation back to 0° without animation
            flipRotation = 0
            // The new image becomes the cached "front" for next flip
            cachedArtwork = newArtwork
        }
    }
    
    // MARK: - Placeholder Album Cover
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
                    .font(.system(size: 13, weight: .semibold, design: .default)) // try 20-22 for desktop
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
    
    // MARK: - Adjust Slider
    @ViewBuilder
    func renderCurrentSongPosition() -> some View {
        if isVisible {
            HStack(spacing: 4) {
                Text(formatDuration(model.nowPlayingInfo.positionSeconds))
                    .font(.system(size: 8, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(spacing: 6) {
                    // Progress bar
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
                            
                            // Thumb
//                            Circle()
//                                .fill(Color(nsColor: model.nowPlayingInfo.dominantColor))
//                                .frame(width: 12, height: 12)
//                                .offset(x: max(CGFloat(effectivePosition / max(model.nowPlayingInfo.durationSeconds, 1)) * geometry.size.width - 6, -6))
                            
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
                    .frame(height: 12)
                }
                .padding(.horizontal, 8)
                
                Text(formatDuration(model.nowPlayingInfo.durationSeconds))
                    .font(.system(size: 8, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
            }
        } else {
            EmptyView()
        }
    }    // Helper function to format seconds as "MM:SS"
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func checkPositionUpdate(targetPosition: Double, attempts: Int) {
        let maxAttempts = 15
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
}
