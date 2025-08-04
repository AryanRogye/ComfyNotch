//
//  PopInPresenter_NowPlaying.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/6/25.
//

import SwiftUI

struct NotchLoadingDot: View {
    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 6, height: 6)
            .scaleEffect(1.1)
            .animation(
                Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: UUID() // force the animation
            )
    }
}

struct PopInPresenter_NowPlaying: View {
    
    @ObservedObject var settingsModel: SettingsModel = .shared
    @ObservedObject var musicModel: MusicPlayerWidgetModel = .shared
    @ObservedObject var notchStateManager: NotchStateManager = .shared
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var animate = false
    
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(alignment: .bottom) {
                Image(systemName: "music.note")
                    .resizable()
                    .frame(width: 10, height: 14)
                    .foregroundStyle(.primary.opacity(0.6))
                
                Text(musicModel.nowPlayingInfo.trackName)
                    .font(.subheadline.weight(.semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.primary.opacity(0.7))

                Image(systemName: "music.microphone")
                    .resizable()
                    .frame(width: 10, height: 14)
                    .foregroundStyle(.primary.opacity(0.6))
                
                Text(musicModel.nowPlayingInfo.artistName)
                    .font(.subheadline.weight(.semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.primary.opacity(0.7))
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 35)
        .clipped()
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .onHover { hovering in
            notchStateManager.hoverHandler.isHoveringOverPopin = hovering
        }
    }
}
