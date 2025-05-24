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
    private let spacing: CGFloat = 8
    private let animationDuration: Double = 0.15 // Shorter for snappier feel

    var body: some View {
        VStack(spacing: spacing) {
            let currentVolume = CGFloat(volumeManager.currentVolume)
            let currentBrightness = CGFloat(brightnessManager.currentBrightness)
            
            HUDBar(icon: "speaker.wave.2.fill", color: dominantColor, fill: currentVolume)
            HUDBar(icon: "sun.max.fill", color: .yellow, fill: currentBrightness)
        }
        .frame(width: hudWidth)
        .drawingGroup() // Rasterize for performance
        // SINGLE animation modifier instead of multiple
        .animation(.easeOut(duration: animationDuration), value: currentValues)
        .onChange(of: musicModel.nowPlayingInfo.dominantColor) { _, newColor in
            dominantColor = Color(nsColor: newColor)
        }
        .onAppear {
            dominantColor = Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
        }
    }
    
    // Combine values for single animation trigger
    private var currentValues: String {
        "\(volumeManager.currentVolume)-\(brightnessManager.currentBrightness)"
    }
}

struct HUDBar: View {
    let icon: String
    let color: Color
    let fill: CGFloat
    
    // Pre-computed constants
    private let barWidth: CGFloat = 170 // Match parent width
    private let barHeight: CGFloat = 10
    private let iconWidth: CGFloat = 20
    private let backgroundOpacity: Double = 0.15
    
    // Pre-calculate fill width to avoid repeated calculations
    private var fillWidth: CGFloat {
        barWidth * max(0, min(fill, 1))
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: iconWidth, height: iconWidth) // Fixed height too
                .imageScale(.medium)
            
            ZStack(alignment: .leading) {
                // Background bar - fixed frame
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(Color.white.opacity(backgroundOpacity))
                    .frame(width: barWidth, height: barHeight)
                
                // Fill bar with pre-calculated width
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(color)
                    .frame(width: fillWidth, height: barHeight)
            }
        }
    }
}
