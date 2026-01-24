//
//  MediaRemoteMusicController.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import Foundation
import SwiftUI
import MediaRemoteAdapter

final class MediaRemoteMusicController: NowPlayingProvider {
    
    @ObservedObject var nowPlayingInfo: NowPlayingInfo
    
    let mediaController = MediaController()
    
    private var lastUpdateTime: Date = .distantPast
    private let updateInterval: TimeInterval = 2.0
    
    private var lastTrackIdentifier: String?
    private var lastArtworkIdentifier: String?
    
    init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
        mediaController.startListening()
    }
    
    func isAvailable() -> Bool {
        /// DEBUG: Return True
        return true
    }
    
    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
        mediaController.onTrackInfoReceived = { [weak self] trackInfo in
            DispatchQueue.main.async {
                guard let self else { return }
                let now = Date()
                
                let trackId = "\(trackInfo.payload.title ?? "")|\(trackInfo.payload.artist ?? "")|\(trackInfo.payload.album ?? "")"
                
                if trackId == self.lastTrackIdentifier {
                    if now.timeIntervalSince(self.lastUpdateTime) < self.updateInterval {
                        debugLog("Skipping update: \(now.timeIntervalSince(self.lastUpdateTime)) seconds since last update", from: .mrmController)
                        return
                    }
                    debugLog("Track ID Matches — updating time only", from: .mrmController)
                } else {
                    self.lastTrackIdentifier = trackId
                }
                
                // Always update lastUpdateTime when passing through
                self.lastUpdateTime = now
                self.nowPlayingInfo.trackName = trackInfo.payload.title ?? "Unknown"
                self.nowPlayingInfo.artistName = trackInfo.payload.artist ?? "Unknown"
                self.nowPlayingInfo.albumName = trackInfo.payload.album ?? "Unknown"
                self.nowPlayingInfo.isPlaying = trackInfo.payload.isPlaying ?? false
                
                self.nowPlayingInfo.durationSeconds = (trackInfo.payload.durationMicros ?? 0) / 1_000_000
                
                if let artworkImage = trackInfo.payload.artwork {
                    let identifier = trackId + (artworkImage.tiffRepresentation?.hashValue.description ?? "")
                    
                    if self.lastArtworkIdentifier != identifier {
                        self.nowPlayingInfo.artworkImage = artworkImage
                        DispatchQueue.global(qos: .utility).async {
                            let color = self.getDominantColor(from: artworkImage) ?? .white
                            DispatchQueue.main.async {
                                self.nowPlayingInfo.dominantColor = color
                            }
                        }
                        self.lastArtworkIdentifier = identifier
                    }
                }
            }
        }
        mediaController.onPlaybackTimeUpdate = { [weak self] time in
            DispatchQueue.main.async {
                guard let self else { return }
                self.nowPlayingInfo.positionSeconds = time
            }
        }
        
        completion(true)
    }
    
    func playPreviousTrack() {
        mediaController.previousTrack()
    }
    
    func playNextTrack() {
        mediaController.nextTrack()
    }
    
    func togglePlayPause() {
        mediaController.togglePlayPause()
    }
    
    func playAtTime(to time: Double) {
        mediaController.setTime(seconds: time)
    }
}
