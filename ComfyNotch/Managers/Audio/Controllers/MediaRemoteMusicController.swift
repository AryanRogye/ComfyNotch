//
//  MediaRemoteMusicController.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import Foundation
import SwiftUI

final class MediaRemoteMusicController: NowPlayingProvider  {
    @ObservedObject var nowPlayingInfo: NowPlayingInfo

init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
    }

    func isAvailable() -> Bool {
        return false
        let frameworkURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, frameworkURL as CFURL) else {
            debugLog("❌ MediaRemote.framework not found.")
            return false
        }

        let fn = "MRMediaRemoteGetNowPlayingInfo" as CFString
        let hasFunc = CFBundleGetFunctionPointerForName(bundle, fn)

        if hasFunc != nil {
            debugLog("✅ MediaRemote is available and MRMediaRemoteGetNowPlayingInfo is loaded.")
            return true
        } else {
            debugLog("⚠️ MediaRemote is present, but GetNowPlayingInfo function is missing.")
            return false
        }
    }

    func getNowPlayingInfo(completion: @escaping (Bool)->Void) {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
              let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
        else {
            return completion(false)
        }
        
        typealias MRFunc = @convention(c) (DispatchQueue, @escaping ([String:Any]?) -> Void) -> Void
        let MR = unsafeBitCast(ptr, to: MRFunc.self)
        
        MR(DispatchQueue.main) { info in
            // if we didn’t actually get a title back, consider it a failure
            guard let info = info,
                  let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
            else {
                return completion(false)
            }
            
            // populate your nowPlayingInfo…
            self.nowPlayingInfo.trackName  = title
            self.nowPlayingInfo.artistName = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown"
            self.nowPlayingInfo.albumName  = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String  ?? "Unknown"
            // …and artwork/color, isPlaying = true, etc.
            
            completion(true)
        }
    }

    /// Actions
    func playPreviousTrack() -> Void {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 5) // 0 = Previous Track
    }
    func playNextTrack() -> Void {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 4) // 1 = Next Track
    }
    func togglePlayPause() -> Void {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 2) // 2 = Play/Pause Toggle
    }
    func playAtTime(to time: Double) -> Void {
        
    }
    
    private func sendCommand(command: String, commandType: Int) {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
            debugLog("Failed to load MediaRemote framework")
            return
        }
        
        guard let pointer = CFBundleGetFunctionPointerForName(bundle, command as CFString) else {
            debugLog("Failed to get \(command) function pointer")
            return
        }
        
        typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, Any?, Int) -> Void
        let MRMediaRemoteSendCommand = unsafeBitCast(pointer, to: MRMediaRemoteSendCommandFunction.self)
        
        // Send the command
        MRMediaRemoteSendCommand(commandType, nil, 0)
    }
}
