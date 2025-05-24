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
    
    @State private var lastVolume: CGFloat = 0
    @State private var lastBrightness: CGFloat = 0
    @State private var dominantColor: Color = .blue // Cache the color
    
    // Pre-computed constants
    private let hudWidth: CGFloat = 160
    private let barWidth: CGFloat = 120
    private let barHeight: CGFloat = 10
    private let iconWidth: CGFloat = 20
    private let spacing: CGFloat = 6
    private let animationDuration: Double = 0.2

    var body: some View {
        VStack(spacing: spacing) {
            if panelState.isLoadingPopInPresenter {
                HUDBar(icon: "speaker.wave.2.fill", color: dominantColor, fill: lastVolume)
                HUDBar(icon: "sun.max.fill", color: .yellow, fill: lastBrightness)
            } else {
                let currentVolume = CGFloat(volumeManager.currentVolume)
                let currentBrightness = CGFloat(brightnessManager.currentBrightness)
                
                HUDBar(icon: "speaker.wave.2.fill", color: dominantColor, fill: currentVolume)
                HUDBar(icon: "sun.max.fill", color: .yellow, fill: currentBrightness)
            }
        }
        .frame(width: hudWidth)
        .drawingGroup()
        .animation(.easeOut(duration: animationDuration), value: volumeManager.currentVolume)
        .animation(.easeOut(duration: animationDuration), value: brightnessManager.currentBrightness)
        .onChange(of: panelState.isLoadingPopInPresenter) { _, isLoading in
            if !isLoading {
                lastVolume = CGFloat(volumeManager.currentVolume)
                lastBrightness = CGFloat(brightnessManager.currentBrightness)
            }
        }
        .onChange(of: musicModel.nowPlayingInfo.dominantColor) { _, newColor in
            dominantColor = Color(nsColor: newColor)
        }
        .onAppear {
            dominantColor = Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
            lastVolume = CGFloat(volumeManager.currentVolume)
            lastBrightness = CGFloat(brightnessManager.currentBrightness)
        }
    }
}

// Extracted as separate view for better performance
struct HUDBar: View {
    let icon: String
    let color: Color
    let fill: CGFloat
    
    // Pre-computed constants
    private let barWidth: CGFloat = 120
    private let barHeight: CGFloat = 10
    private let iconWidth: CGFloat = 20
    private let backgroundOpacity: Double = 0.15
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: iconWidth)
                .imageScale(.medium) // Explicit scale for consistency
            
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(Color.white.opacity(backgroundOpacity))
                    .frame(width: barWidth, height: barHeight)
                
                // Fill bar - using RoundedRectangle instead of Capsule for better performance
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(color)
                    .frame(width: barWidth * max(0, min(fill, 1)), height: barHeight)
            }
        }
    }
}
