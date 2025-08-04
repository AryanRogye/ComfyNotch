//
//  PopInPresenter_NowPlaying.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/6/25.
//

import SwiftUI

struct PopInPresenter_NowPlaying: View {
    
    @ObservedObject var settingsModel: SettingsModel = .shared
    @ObservedObject var musicModel: MusicPlayerWidgetModel = .shared
    @ObservedObject var notchStateManager: NotchStateManager = .shared
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var animate = false
    
    
    @State private var isHoveringInternals : Bool = false
    @State private var isHoveringOverLeft = false
    @State private var isHoveringOverRight = false
    
    private var showControls: Bool {
        settingsModel.enableButtonsOnHover &&
        notchStateManager.hoverHandler.scaleHoverOverLeftItems &&
        isHoveringInternals
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                content
                    .padding(.vertical, 4)
            }
            
            if showControls {
                playbackControls
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 35)
        .clipped()
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .onHover { hovering in
            notchStateManager.hoverHandler.isHoveringOverPopin =
            hovering && settingsModel.enableButtonsOnHover
        }
        .onHover { hovering in
            isHoveringInternals = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHoveringOverLeft)
        .animation(.easeInOut(duration: 0.15), value: isHoveringOverRight)
    }
    
    // MARK: - Content
    private var content: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Image(systemName: "music.note")
                .resizable()
                .frame(width: 10, height: 14)
                .foregroundStyle(.primary.opacity(isHoveringOverLeft ? 0.1 : 0.6))
                .accessibilityIdentifier("PopInPresenter_NowPlaying_musicNote")
            
            Text(musicModel.nowPlayingInfo.trackName)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary.opacity(isHoveringOverLeft ? 0.1 : 0.7))

            Image(systemName: "music.microphone")
                .resizable()
                .frame(width: 10, height: 14)
                .foregroundStyle(.primary.opacity(isHoveringOverRight ? 0.1 : 0.6))
                .accessibilityIdentifier("PopInPresenter_NowPlaying_microphone")
            
            Text(musicModel.nowPlayingInfo.artistName)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary.opacity(isHoveringOverRight ? 0.1 : 0.7))
        }
    }
    

    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 0) {
            // Left half - Previous
            Button(action: AudioManager.shared.playPreviousTrack) {
                ZStack {
                    // Full half tap area
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(
                            isHoveringOverLeft
                                ? 0.15
                                : 0.1
                            )
                        )
                        .contentShape(Rectangle())
                    
                    // Visual icon
                    Image(systemName: "backward.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .scaleEffect(isHoveringOverLeft ? 1.0 : 0.9)
            .onHover { hovering in
                isHoveringOverLeft = hovering
            }
            
            // Right half - Next
            Button(action: AudioManager.shared.playNextTrack) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(
                            isHoveringOverRight
                                ? 0.15
                                : 0.1
                            )
                        )
                        .contentShape(Rectangle())
                    
                    Image(systemName: "forward.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .scaleEffect(isHoveringOverRight ? 1.0 : 0.9)
            .onHover { hovering in
                isHoveringOverRight = hovering
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
