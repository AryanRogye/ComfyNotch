//
//  NowPlayingProvider.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

protocol NowPlayingProvider {
    func isAvailable() -> Bool
    
    func getNowPlayingInfo() -> Void
    
    /// Actions
    func playPreviousTrack() -> Void
    func playNextTrack() -> Void
    func togglePlayPause() -> Void
    func playAtTime(to time: Double) -> Void
}
