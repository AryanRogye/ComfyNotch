//
//  PopInPresenter_Volume.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI

struct PopInPresenter_HUD: View {
    
    @StateObject private var brightnessManager: BrightnessWatcher = .shared
    @StateObject private var volumeManager: VolumeManager = .shared
    @StateObject private var musicModel: MusicPlayerWidgetModel = .shared
    @StateObject var panelState: PanelAnimationState = .shared
    
    @State private var dominantColor: Color = .blue
    
    // Pre-computed constants
    private let hudWidth: CGFloat = 200
    private let spacing: CGFloat = 2
    private let animationDuration: Double = 0.08

    var body: some View {
        VStack(spacing: spacing) {
            HUDBar(
                icon: "speaker.wave.2.fill",
                color: dominantColor,
                fill: CGFloat(volumeManager.currentVolume)
            )
            HUDBar(
                icon: "sun.max.fill",
                color: .yellow,
                fill: CGFloat(brightnessManager.currentBrightness)
            )
        }
        .frame(width: hudWidth, height: 30)
        .onAppear {
            dominantColor = Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
        }
        .onChange(of: musicModel.nowPlayingInfo.dominantColor) { _, newColor in
            withAnimation(.easeOut(duration: 0.2)) {
                dominantColor = Color(nsColor: newColor)
            }
        }
    }
}

struct HUDBar: View {
    let icon: String
    let color: Color
    let fill: CGFloat
    
    // Pre-computed constants
    private let barWidth: CGFloat = 170
    private let barHeight: CGFloat = 10
    private let iconWidth: CGFloat = 20
    private let backgroundOpacity: Double = 0.15
    private let cornerRadius: CGFloat = 5
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: iconWidth, height: iconWidth)
                .imageScale(.medium)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white.opacity(backgroundOpacity))
                    
                    // Fill bar with smooth animation
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                        .frame(width: geometry.size.width * max(0, min(fill, 1)))
                        .animation(.easeOut(duration: 0.1), value: fill)
                }
            }
            .frame(height: barHeight)
        }
    }
}
