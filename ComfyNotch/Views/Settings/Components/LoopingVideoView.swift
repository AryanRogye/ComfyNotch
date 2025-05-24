//
//  LoopingVideoView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI
import AVKit

struct LoopingVideoView: View {
    let url: URL

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // no interaction
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.volume = 0 // 🔇 mute
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer
    }
}
