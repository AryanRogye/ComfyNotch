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
    private let mediaRemotePath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
    private let handle: UnsafeMutableRawPointer?

    init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
        self.handle = dlopen(mediaRemotePath, RTLD_NOW)
        if handle == nil {
            debugLog("❌ Failed to open MediaRemote via dlopen.")
        }
    }

    deinit {
        if let handle = handle {
            dlclose(handle)
        }
    }

    func isAvailable() -> Bool {
        return false
        guard let handle = handle else { return false }
        return dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") != nil
    }

    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
        guard let handle = handle,
              let ptr = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo")
        else {
            debugLog("❌ MRMediaRemoteGetNowPlayingInfo not found.")
            return completion(false)
        }

        typealias MRFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
        let MR = unsafeBitCast(ptr, to: MRFunc.self)

        MR(DispatchQueue.main) { info in
            guard let info = info,
                  let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
            else {
                return completion(false)
            }

            self.nowPlayingInfo.trackName = title
            self.nowPlayingInfo.artistName = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown"
            self.nowPlayingInfo.albumName  = info["kMRMediaRemoteNowPlayingInfoAlbum"]  as? String ?? "Unknown"
            // You can add artwork/color, isPlaying, etc. here

            completion(true)
        }
    }

    // MARK: - Actions

    func playPreviousTrack() {
        sendCommand(commandType: 0) // Previous
    }

    func playNextTrack() {
        sendCommand(commandType: 1) // Next
    }

    func togglePlayPause() {
        sendCommand(commandType: 2) // Toggle
    }

    func playAtTime(to time: Double) {
        // Not implemented
    }

    private func sendCommand(commandType: Int) {
        guard let handle = handle,
              let ptr = dlsym(handle, "MRMediaRemoteSendCommand")
        else {
            debugLog("❌ MRMediaRemoteSendCommand not found.")
            return
        }

        typealias SendCommandFunc = @convention(c) (Int, Any?, Int) -> Void
        let sendCommand = unsafeBitCast(ptr, to: SendCommandFunc.self)

        sendCommand(commandType, nil, 0)
    }
}
