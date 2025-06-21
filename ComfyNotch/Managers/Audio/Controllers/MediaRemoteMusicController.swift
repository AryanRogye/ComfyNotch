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
//                        print("Skipping update: \(now.timeIntervalSince(self.lastUpdateTime)) seconds since last update")
                        return
                    }
                    print("Track ID Matches — updating time only")
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
                    
                    self.nowPlayingInfo.artworkImage = artworkImage
                    
                    if self.lastArtworkIdentifier != identifier {
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

//final class MediaRemoteMusicController: NowPlayingProvider {
//    @ObservedObject var nowPlayingInfo: NowPlayingInfo
//    private let mediaRemotePath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
//    private let handle: UnsafeMutableRawPointer?
//
//    init(nowPlayingInfo: NowPlayingInfo) {
//        self.nowPlayingInfo = nowPlayingInfo
//        self.handle = dlopen(mediaRemotePath, RTLD_NOW)
//        if handle == nil {
//            debugLog("❌ Failed to open MediaRemote via dlopen.")
//        }
//    }
//
//    deinit {
//        if let handle = handle {
//            dlclose(handle)
//        }
//    }
//
//    func isAvailable() -> Bool {
//        return false
////        guard let handle = handle else { return false }
////        return dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") != nil
//    }
//
//    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
//        guard let handle = handle,
//              let ptr = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo")
//        else {
//            debugLog("❌ MRMediaRemoteGetNowPlayingInfo not found.")
//            return completion(false)
//        }
//
//        typealias MRFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
//        let MR = unsafeBitCast(ptr, to: MRFunc.self)
//
//        MR(DispatchQueue.main) { info in
//            guard let info = info,
//                  let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
//            else {
//                return completion(false)
//            }
//
//            self.nowPlayingInfo.trackName = title
//            self.nowPlayingInfo.artistName = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown"
//            self.nowPlayingInfo.albumName  = info["kMRMediaRemoteNowPlayingInfoAlbum"]  as? String ?? "Unknown"
//            // You can add artwork/color, isPlaying, etc. here
//
//            completion(true)
//        }
//    }
//
//    // MARK: - Actions
//
//    func playPreviousTrack() {
//        sendCommand(commandType: 0) // Previous
//    }
//
//    func playNextTrack() {
//        sendCommand(commandType: 1) // Next
//    }
//
//    func togglePlayPause() {
//        sendCommand(commandType: 2) // Toggle
//    }
//
//    func playAtTime(to time: Double) {
//        // Not implemented
//    }
//
//    private func sendCommand(commandType: Int) {
//        guard let handle = handle,
//              let ptr = dlsym(handle, "MRMediaRemoteSendCommand")
//        else {
//            debugLog("❌ MRMediaRemoteSendCommand not found.")
//            return
//        }
//
//        typealias SendCommandFunc = @convention(c) (Int, Any?, Int) -> Void
//        let sendCommand = unsafeBitCast(ptr, to: SendCommandFunc.self)
//
//        sendCommand(commandType, nil, 0)
//    }
//}
