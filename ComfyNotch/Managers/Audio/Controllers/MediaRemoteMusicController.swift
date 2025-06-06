//
//  MediaRemoteMusicController.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import Foundation
import SwiftUI

final class MediaRemoteMusicController: NowPlayingProvider {
    @ObservedObject var nowPlayingInfo: NowPlayingInfo
    private var controller: MediaRemoteControllerRef?
    
    init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
        self.controller = createMediaRemoteController()
        
        if let controller = controller, initializeMediaRemoteController(controller) {
            debugLog("✅ MediaRemote initialized.")
        } else {
            debugLog("❌ Failed to initialize MediaRemoteController.")
        }
    }
    
    func isAvailable() -> Bool {
        return controller != nil
    }
    
    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
        guard let controller = controller else {
            completion(false)
            return
        }
        
        getNowPlayingInfoController(controller) { success in
            if success {
                // Optionally fetch from sharedController if it has nowPlayingInfo stored
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func playPreviousTrack() {
        if let c = controller { sendPreviousTrackCommandController(c) }
    }
    
    func playNextTrack() {
        if let c = controller { sendNextTrackCommandController(c) }
    }
    
    func togglePlayPause() {
        if let c = controller { sendTogglePlayPauseCommandController(c) }
    }
    
    func playAtTime(to time: Double) {
        // Not implemented
    }
}
