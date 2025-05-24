//
//  PopInPresenter_Volume.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI

struct PopInPresenter_Volume: View {
    
    @StateObject private var brightnessManager: BrightnessWatcher = .shared
    @StateObject private var volumeManager: VolumeManager = .shared
    @StateObject private var musicModel: MusicPlayerWidgetModel = .shared

    var body: some View {
        VStack(spacing: 6) {
            // Volume Bar
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.white)
                    .frame(width: 20)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 10)
                    
                    Capsule()
                        .fill(Color(nsColor: musicModel.nowPlayingInfo.dominantColor))
                        .frame(width: CGFloat(volumeManager.currentVolume) * 120, height: 10)
                        .animation(.easeOut(duration: 0.2), value: volumeManager.currentVolume)
                }
            }

            // Brightness Bar
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 20)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 10)
                    
                    Capsule()
                        .fill(Color.yellow)
                        .frame(width: CGFloat(brightnessManager.currentBrightness) * 120, height: 10)
                        .animation(.easeOut(duration: 0.2), value: brightnessManager.currentBrightness)
                }
            }
        }
        .frame(width: 160)
    }
}
