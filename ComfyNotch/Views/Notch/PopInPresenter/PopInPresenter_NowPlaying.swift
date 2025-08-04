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
    }
    
    // MARK: - Content
    private var content: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Image(systemName: "music.note")
                .resizable()
                .frame(width: 10, height: 14)
                .foregroundStyle(.primary.opacity(0.6))
                .accessibilityIdentifier("PopInPresenter_NowPlaying_musicNote")
            
            Text(musicModel.nowPlayingInfo.trackName)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary.opacity(0.7))
            
            Image(systemName: "music.microphone")
                .resizable()
                .frame(width: 10, height: 14)
                .foregroundStyle(.primary.opacity(0.6))
                .accessibilityIdentifier("PopInPresenter_NowPlaying_microphone")
            
            Text(musicModel.nowPlayingInfo.artistName)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary.opacity(0.7))
        }
    }
    
    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 0) {
            // Left half - Previous track
            Button(action: AudioManager.shared.playPreviousTrack) {
                ZStack {
                    Color.clear
                    
                    // Visual indicator (only show the icon)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "backward.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.primary)
                        )
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle()) // Make entire left half clickable
            
            // Right half - Next track
            Button(action:AudioManager.shared.playNextTrack) {
                ZStack {
                    Color.clear
                    // Visual indicator (only show the icon)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "forward.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.primary)
                        )
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle()) // Make entire right half clickable
        }
    }
}
