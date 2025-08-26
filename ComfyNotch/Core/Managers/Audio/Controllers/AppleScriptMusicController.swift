//
//  AppleScriptMusicController.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import Foundation
import SwiftUI

/// A fallback NowPlayingProvider implementation using AppleScript to control and fetch information from Spotify and Apple Music.
///
/// This controller interacts with Spotify and Apple Music via AppleScript, allowing playback control and retrieval of now playing information.
/// It is used when the MediaRemote private API is unavailable or fails, providing a robust backup for music control features.
final class AppleScriptMusicController: NowPlayingProvider {
    /// The shared NowPlayingInfo object to update UI and state.
    @ObservedObject var nowPlayingInfo: NowPlayingInfo
    
    /// Values To Ensure That ArtWork Images Dont Get Asked For (Apple Music pulls from
    /// a temporary folder a image with the name cover.jpg, this could be very heavy)
    private var lastArtworkIdentifier: String?
    
    // MARK: - Optimization Properties
    private var lastUpdateTime: Date = Date()
    private var updateInterval: TimeInterval = 2.0
    private var lastTrackInfo: String = ""
    private var isUpdating = false
    // Cache for app running status
    private var spotifyRunningCache: (isRunning: Bool, timestamp: Date)?
    private var appleMusicRunningCache: (isRunning: Bool, timestamp: Date)?
    private let appStatusCacheInterval: TimeInterval = 5.0 // Cache app status for 5 seconds
    
    /// Initializes the controller with a NowPlayingInfo object.
    /// - Parameter nowPlayingInfo: The shared info object to update.
    init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    /// Always returns true, as this fallback is always available if the app is running.
    /// - Returns: `true` indicating the provider can be used.
    func isAvailable() -> Bool {
        true
    }
    
    private var is_sp_playing = false
    private var is_it_playing = false
    
    
    /// Fetches the current now playing information from Spotify or Apple Music.
    ///
    /// The method checks which app is playing, fetches info accordingly, and updates the NowPlayingInfo.
    /// If neither app is playing, it clears the now playing info.
    /// - Parameter completion: Closure called with `true` when done (always true for compatibility).
    func getNowPlayingInfo(completion: @escaping (Bool)->Void) {
        //        debugLog("Getting Now Playing From AppleScriptMusicController")
        guard !isUpdating else {
            completion(true)
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) < updateInterval {
            completion(true)
            return
        }
        
        isUpdating = true
        lastUpdateTime = now
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.performUpdate { success in
                DispatchQueue.main.async {
                    self?.isUpdating = false
                    completion(success)
                }
            }
        }
    }
    
    private func performUpdate(completion: @escaping (Bool) -> Void) {
        self.is_sp_playing = isSpotifyPlaying()
        self.is_it_playing = isAppleMusicPlaying()
        
        if !is_sp_playing && !is_it_playing {
            self.updateInterval = 5.0
        } else {
            self.updateInterval = 2.0
        }
        
        // Shortcut if nothing is playing
        if !is_sp_playing && !is_it_playing {
            DispatchQueue.main.async {
                self.clearNowPlaying()
                self.nowPlayingInfo.musicProvider = .none
                completion(true)
            }
            return
        }
        
        // If Spotify is playing
        if is_sp_playing {
            getSpotifyInfo { info in
                DispatchQueue.main.async {
                    if let info = info {
                        self.updateNowPlaying(with: info, isPlaying: true)
                        self.nowPlayingInfo.musicProvider = .spotify
                    } else {
                        self.clearNowPlaying()
                        self.nowPlayingInfo.musicProvider = .none
                    }
                    completion(true)
                }
            }
            return
        }
        
        // If Apple Music is playing
        if is_it_playing {
            DispatchQueue.main.async {
                if let info = self.getMusicInfo() {
                    self.updateNowPlaying(with: info, isPlaying: true)
                    self.nowPlayingInfo.musicProvider = .apple_music
                } else {
                    self.clearNowPlaying()
                    self.nowPlayingInfo.musicProvider = .none
                }
                completion(true)
            }
            return
        }
        
        // fallback: shouldn't reach here, but just in case
        completion(true)
    }
    
    // MARK: - Playback Actions
    /// Skips to the previous track in the current player.
    func playPreviousTrack() -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.is_sp_playing {
                _ = self.runAppleScript("""
                    tell application \"Spotify\"
                        previous track
                    end tell
                """)
            } else if self.is_it_playing {
                _ = self.runAppleScript("""
                    tell application \"Music\"
                        previous track
                    end tell
                """)
            }
        }
    }
    /// Skips to the next track in the current player.
    func playNextTrack() -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.is_sp_playing {
                _ = self.runAppleScript("""
                    tell application \"Spotify\"
                        next track
                    end tell
                """)
            } else if self.is_it_playing {
                _ = self.runAppleScript("""
                    tell application \"Music\"
                        next track
                    end tell
                """)
            }
        }
    }
    /// Toggles play/pause in the current player.
    func togglePlayPause() -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.is_sp_playing {
                _ = self.runAppleScript("""
                    tell application \"Spotify\"
                        playpause
                    end tell
                """)
            } else if self.is_it_playing {
                _ = self.runAppleScript("""
                    tell application \"Music\"
                        playpause
                    end tell
                """)
            }
            /// Reset Cache
            self.spotifyRunningCache = nil
            self.appleMusicRunningCache = nil
            self.lastTrackInfo = ""
            self.lastArtworkIdentifier = nil
            self.lastUpdateTime = .distantPast
        }
    }
    /// Seeks playback to a specific time in the current track.
    /// - Parameter time: The time (in seconds) to seek to.
    func playAtTime(to time: Double) -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.is_sp_playing {
                _ = self.runAppleScript("""
                    tell application \"Spotify\"
                        set player position to \(time)
                    end tell
                """)
            } else if self.is_it_playing {
                _ = self.runAppleScript("""
                    tell application \"Music\"
                        set player position to \(time)
                    end tell
                """)
            }
        }
    }
    
    // MARK: - Optimized App Status Checking
    func isSpotifyPlaying() -> Bool {
        return isAppRunningCached("Spotify", cache: &spotifyRunningCache)
    }
    
    func isAppleMusicPlaying() -> Bool {
        return isAppRunningCached("Music", cache: &appleMusicRunningCache)
    }
    
    private func isAppRunningCached(_ appName: String, cache: inout (isRunning: Bool, timestamp: Date)?) -> Bool {
        let now = Date()
        
        // Check if we have a valid cache entry
        if let cacheEntry = cache,
           now.timeIntervalSince(cacheEntry.timestamp) < appStatusCacheInterval {
            return cacheEntry.isRunning
        }
        
        // Cache miss - check actual status
        let isRunning = isAppRunning(appName)
        cache = (isRunning: isRunning, timestamp: now)
        return isRunning
    }
    
    // MARK: - Internal Functions
    /// Checks if a specific app is running using AppleScript.
    /// - Parameter appName: The name of the app (e.g., "Spotify" or "Music").
    /// - Returns: `true` if the app is running, otherwise `false`.
    private func isAppRunning(_ appName: String) -> Bool {
        let script = """
        tell application \"System Events\"
            set isRunning to (name of processes) contains \"\(appName)\"
        end tell
        return isRunning
        """
        if let output = runAppleScript(script) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        }
        return false
    }
    
    // MARK: - AppleScript Execution
    ///
    /// Executes an AppleScript and returns the result as a string.
    /// - Parameter script: The AppleScript source code.
    /// - Returns: The result string, or `nil` if execution failed.
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)
            if let error = error {
                debugLog("AppleScript Error: \(error)")
            }
            // debugLog("No Error in AppleScript Execution")
            // debugLog("Script: \(script)\n\n\n")
            // debugLog("Value: \(result.stringValue ?? "nil")")
            return result.stringValue
        }
        return nil
    }
    
    /// Clears the now playing info, resetting all fields to default values.
    private func clearNowPlaying() {
        nowPlayingInfo.trackName = "No Song Playing"
        nowPlayingInfo.artistName = "Unknown Artist"
        nowPlayingInfo.albumName = "Unknown Album"
        nowPlayingInfo.artworkImage = nil
        nowPlayingInfo.dominantColor = .white
        nowPlayingInfo.isPlaying = false
        
        lastTrackInfo = ""
        lastArtworkIdentifier = nil
    }
    
    /**
     * Updates the current playing media information with provided data.
     * Also extracts and updates the dominant color from artwork.
     * - Parameter info: Tuple containing track name, artist, album, artwork, position, and duration.
     */
    private func updateNowPlaying(
        with info: (String, String, String, NSImage?, Double, Double),
        isPlaying: Bool
    ) {
        let (trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds) = info
        let currentTrackIdentifier = "\(trackName)|\(artistName)|\(albumName)|\(isPlaying)"
        
        if lastTrackInfo == currentTrackIdentifier {
            // Only update time-sensitive info
            nowPlayingInfo.positionSeconds = positionSeconds
            nowPlayingInfo.durationSeconds = durationSeconds
            return
        }
        
        lastTrackInfo = currentTrackIdentifier
        
        nowPlayingInfo.trackName = trackName
        nowPlayingInfo.artistName = artistName
        nowPlayingInfo.albumName = albumName
        
        // Only update dominant color if artwork changed
        if let artworkImage = artworkImage, let imageHash = hashImage(artworkImage) {
            let currentArtworkIdentifier = "\(trackName)|\(albumName)|\(imageHash)"
            
            if lastArtworkIdentifier != currentArtworkIdentifier {
                nowPlayingInfo.artworkImage = artworkImage
                // Process dominant color on background queue
                DispatchQueue.global(qos: .utility).async {
                    let dominantColor = self.getDominantColor(from: artworkImage) ?? .white
                    DispatchQueue.main.async {
                        self.nowPlayingInfo.dominantColor = dominantColor
                    }
                }
                lastArtworkIdentifier = currentArtworkIdentifier
            }
        } else {
            nowPlayingInfo.dominantColor = .white
        }
        
        // Update the current time and duration
        nowPlayingInfo.positionSeconds = positionSeconds
        nowPlayingInfo.durationSeconds = durationSeconds
        nowPlayingInfo.isPlaying = true
    }
    
    // MARK: - Spotify
    
    /**
     * Fetches current playing information from Spotify.
     * Returns tuple of (track, artist, album, artwork, position, duration) if successful.
     * - Parameter completion: Closure called with the info tuple or nil.
     */
    private func getSpotifyInfo(completion: @escaping ((String, String, String, NSImage?, Double, Double)?) -> Void) {
        let script = """
        tell application \"Spotify\"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set artworkURL to artwork url of current track
                set currentTime to player position
                set trackDuration to (duration of current track) / 1000
                return trackName & \"||\" & artistName & \"||\" & albumName & \"||\" & artworkURL & \"||\" & currentTime & \"||\" & trackDuration
            else
                return \"not_playing\"
            end if
        end tell
        """
        
        if let output = runAppleScript(script), output != "not_playing" {
            let components = output.components(separatedBy: "||")
            if components.count == 6 {
                let trackName = components[0]
                let artistName = components[1]
                let albumName = components[2]
                let artworkURLString = components[3]
                let positionSeconds = Double(components[4]) ?? 0.0
                let durationSeconds = Double(components[5]) ?? 0.0
                
                // Only fetch artwork if track changed
                let trackIdentifier = trackName + albumName
                if lastArtworkIdentifier != trackIdentifier, let artworkURL = URL(string: artworkURLString) {
                    URLSession.shared.dataTask(with: artworkURL) { data, response, error in
                        var artworkImage: NSImage? = nil
                        if let data = data {
                            artworkImage = NSImage(data: data)
                        }
                        completion((trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds))
                    }.resume()
                    return
                } else {
                    // Use existing artwork or nil
                    completion((trackName, artistName, albumName, nil, positionSeconds, durationSeconds))
                    return
                }
            }
        }
        completion(nil)
    }
    
    // MARK: - Apple Music
    
    /**
     * Fetches current playing information from Music app.
     * Returns tuple of (track, artist, album, artwork, position, duration) if successful.
     * - Returns: Tuple with info, or nil if not available.
     */
    private func getMusicInfo() -> (String, String, String, NSImage?, Double, Double)? {
        let script = """
        tell application "Music"
            try
                set playerState to player state is playing
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set currentTrackAlbum to album of current track
                set trackPosition to player position
                set trackDuration to duration of current track
                set shuffleState to shuffle enabled
                set repeatState to false
        
                try
                    set artData to data of artwork 1 of current track
                    set tempPath to POSIX path of (path to temporary items folder) & "cover.jpg"
                    set outFile to open for access POSIX file tempPath with write permission
                    set eof of outFile to 0
                    write artData to outFile
                    close access outFile
                on error
                    set tempPath to ""
                end try
        
                return (playerState & "||" & currentTrackName & "||" & currentTrackArtist & "||" & currentTrackAlbum & "||" & trackPosition & "||" & trackDuration & "||" & shuffleState & "||" & repeatState & "||" & tempPath) as string
            on error
                return "false||Not Playing||Unknown||Unknown||0||0||false||false||"
            end try
        end tell
        """
        
        /// The Image Will Never Work, A Working Version in my terminal was having it getting sent to a temporary folder
        /// the name of the image will be saved as cover.jpg
        
        if let output = runAppleScript(script) {
            let components = output.components(separatedBy: "||")
            
            if components.count >= 9 {
                let trackName = components[1]
                let artistName = components[2]
                let albumName = components[3]
                let positionSeconds = Double(components[4]) ?? 0.0
                let durationSeconds = Double(components[5]) ?? 0.0
                let artworkPath = components[8].trimmingCharacters(in: .whitespacesAndNewlines)
                
                //                var artworkImage: NSImage? = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Placeholder")
                var artworkImage: NSImage? = nil
                
                /// We Have To Check if the artworkPath is empty
                if !artworkPath.isEmpty, FileManager.default.fileExists(atPath: artworkPath) {
                    artworkImage = NSImage(contentsOfFile: artworkPath)
                }
                
                return (trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds)
            }
        }
        
        return nil
    }
    
    func hashImage(_ image: NSImage) -> Int? {
        guard let tiffData = image.tiffRepresentation else { return nil }
        return tiffData.hashValue
    }
}
// End of AppleScriptMusicController.swift
