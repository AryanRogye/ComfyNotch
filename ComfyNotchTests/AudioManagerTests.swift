//
//  AudioManagerTests.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/4/25.
//

import XCTest
import AppKit
@testable import ComfyNotch

final class AudioManagerTests: XCTestCase {
    
    private func playSong(_ name: String) {
        let script = """
        tell application "Spotify"
            activate
            play track "\(name)"
        end tell
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
        
        if let error = error {
            XCTFail("AppleScript failed: \(error)")
        }
    }
    
    private func openSpotify() {
        print("Opening Spotify...")
        let spotifyPath = "/Applications/Spotify.app"
        let spotifyURL = URL(fileURLWithPath: spotifyPath)
        
        let success = NSWorkspace.shared.open(spotifyURL)
        XCTAssertTrue(success, "Failed to open Spotify")
    }
    
    private func closeSpotify() {
        print("Closing Spotify...")
        let runningApps = NSWorkspace.shared.runningApplications
        if let spotifyApp = runningApps.first(where: { $0.bundleIdentifier == "com.spotify.client" }) {
            spotifyApp.terminate()
        }
    }
    
    private func playSong() {
        playSong("spotify:track:4jVBIpuOiMj1crqd8LoCrJ")
    }
    
    private func testNowPlayingInfo() {
        let nowPlayingInfo = AudioManager.shared.nowPlayingInfo
        
        /// MUSIC SHOULD BE PLAYING
        if !nowPlayingInfo.isPlaying  {
            XCTFail("Now Playing Info is not playing")
        }
        /// Music Should Have Franchise In Track Name
        if !nowPlayingInfo.trackName.contains("FRANCHISE") {
            XCTFail("Now Playing Info track name does not contain 'FRANCHISE'")
        }
        
        /// Show A message Saying Everything Works
        XCTAssertTrue(true, "Now Playing Info is working correctly")
    }
    
    func testOpeningSpotify() {
        print("🎧 Fetching NowPlaying info from AudioManager...")
        
        closeSpotify()
        
        openSpotify()
        sleep(2)
        
        playSong()
        sleep(2)
        
        /// Not A Test Just Close it
        closeSpotify()
    }
}
