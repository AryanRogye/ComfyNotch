//
//  LoopingVideoView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI
import AVKit

struct LoopingVideoVieww: View {
    let url: URL

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        GeometryReader { geometry in
            if let player = player {
                MacVideoPlayerView(player: player)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // ensures it won't overflow
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .frame(width: 260, height: 125) // 🔐 this is the hard limit
        .cornerRadius(10)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            /// Prevent memory leaks
            player?.pause()
            player?.removeAllItems()
            looper = nil
            player = nil
        }
    }

    private func setupPlayer() {
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.volume = 0
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer
    }
}

struct MacVideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        view.videoGravity = .resize
        view.setAccessibilityElement(false)
        view.focusRingType = .none
        
        return view
    }
    
    func dismantleNSView(_ nsView: AVPlayerView, coordinator: ()) {
        nsView.player = nil
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

