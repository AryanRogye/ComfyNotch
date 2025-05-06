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
    
    /// Fetches the current now playing information from Spotify or Apple Music.
    ///
    /// The method checks which app is playing, fetches info accordingly, and updates the NowPlayingInfo.
    /// If neither app is playing, it clears the now playing info.
    /// - Parameter completion: Closure called with `true` when done (always true for compatibility).
    func getNowPlayingInfo(completion: @escaping (Bool)->Void) {
        if !isSpotifyPlaying() && !isAppleMusicPlaying() {
            /// If neither Spotify nor Apple Music is playing, clear the now playing info.
            clearNowPlaying()
            self.nowPlayingInfo.musicProvider = .none
        } else if isSpotifyPlaying() {
            /// If Spotify is playing, get the info from Spotify.
            getSpotifyInfo { info in
                if let info = info {
                    self.updateNowPlaying(with: info)
                    self.nowPlayingInfo.musicProvider = .spotify
                } else if self.isAppleMusicPlaying(), let musicInfo = self.getMusicInfo() {
                    /// If Spotify info is nil, try Apple Music.
                    self.updateNowPlaying(with: musicInfo)
                    self.nowPlayingInfo.musicProvider = .apple_music
                } else {
                    /// If both are nil, clear the now playing info.
                    self.clearNowPlaying()
                    self.nowPlayingInfo.musicProvider = .none
                }
            }
        } else {
            if let info = self.getMusicInfo() {
                self.updateNowPlaying(with: info)
                self.nowPlayingInfo.musicProvider = .apple_music
            } else {
                self.clearNowPlaying()
                self.nowPlayingInfo.musicProvider = .none
            }
        }
        /// Function will always return true, the Bool is mostly for other protocols that it may fail for.
        completion(true)
    }
    
    // MARK: - Playback Actions
    /// Skips to the previous track in the current player.
    func playPreviousTrack() -> Void {
        if isSpotifyPlaying() {
            _ = runAppleScript("""
                tell application \"Spotify\"
                    previous track
                end tell
            """)
        } else if isAppleMusicPlaying() {
            _ = runAppleScript("""
                tell application \"Music\"
                    previous track
                end tell
            """)
        } else {
            /// Do Nothing
        }
    }
    /// Skips to the next track in the current player.
    func playNextTrack() -> Void {
        if isSpotifyPlaying() {
            _ = runAppleScript("""
                tell application \"Spotify\"
                    next track
                end tell
            """)
        } else if isAppleMusicPlaying() {
            _ = runAppleScript("""
                tell application \"Music\"
                    next track
                end tell
            """)
        } else {
            /// Do Nothing
        }
    }
    /// Toggles play/pause in the current player.
    func togglePlayPause() -> Void {
        if isSpotifyPlaying() {
            _ = runAppleScript("""
                tell application \"Spotify\"
                    playpause
                end tell
            """)
        } else if isAppleMusicPlaying() {
            _ = runAppleScript("""
                tell application \"Music\"
                    playpause
                end tell
            """)
        } else {
            /// Do Nothing
        }
    }
    /// Seeks playback to a specific time in the current track.
    /// - Parameter time: The time (in seconds) to seek to.
    func playAtTime(to time: Double) -> Void {
        if isSpotifyPlaying() {
            _ = runAppleScript("""
                tell application \"Spotify\"
                    set player position to \(time)
                end tell
            """)
        } else if isAppleMusicPlaying() {
            _ = runAppleScript("""
                tell application \"Music\"
                    set player position to \(time)
                end tell
            """)
        } else {
            // Do Nothing
        }
    }

    /// Checks if Spotify is currently running.
    /// - Returns: `true` if Spotify is running, otherwise `false`.
    func isSpotifyPlaying() -> Bool {
        return isAppRunning("Spotify")
    }
    /// Checks if Apple Music is currently running.
    /// - Returns: `true` if Music is running, otherwise `false`.
    func isAppleMusicPlaying() -> Bool {
        return isAppRunning("Music")
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

    /// Executes an AppleScript and returns the result as a string.
    /// - Parameter script: The AppleScript source code.
    /// - Returns: The result string, or `nil` if execution failed.
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
            }
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
    }

    /**
     * Updates the current playing media information with provided data.
     * Also extracts and updates the dominant color from artwork.
     * - Parameter info: Tuple containing track name, artist, album, artwork, position, and duration.
     */
    private func updateNowPlaying(with info: (String, String, String, NSImage?, Double, Double)) {
        let (trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds) = info

        nowPlayingInfo.trackName = trackName
        nowPlayingInfo.artistName = artistName
        nowPlayingInfo.albumName = albumName
        nowPlayingInfo.artworkImage = artworkImage
        if let artworkImage = artworkImage {
            nowPlayingInfo.dominantColor = self.getDominantColor(from: artworkImage) ?? .white
        }
        nowPlayingInfo.isPlaying = true

        // Update the current time and duration
        nowPlayingInfo.positionSeconds = positionSeconds
        nowPlayingInfo.durationSeconds = durationSeconds
    }

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
                return trackName & \" - \" & artistName & \" - \" & albumName & \" - \" & artworkURL & \" - \" & currentTime & \" - \" & trackDuration
            end if
        end tell
        """

        if let output = runAppleScript(script) {
            let components = output.components(separatedBy: " - ")
            if components.count == 6 {
                let trackName = components[0]
                let artistName = components[1]
                let albumName = components[2]
                let artworkURLString = components[3]
                let positionSeconds = Double(components[4]) ?? 0.0
                let durationSeconds = Double(components[5]) ?? 0.0

                if let artworkURL = URL(string: artworkURLString) {
                    // Fetch artwork asynchronously
                    URLSession.shared.dataTask(with: artworkURL) { data, response, error in
                        var artworkImage: NSImage? = nil
                        if let data = data {
                            artworkImage = NSImage(data: data)
                        }
                        // Call completion handler back on MAIN thread
                        DispatchQueue.main.async {
                            completion((trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds))
                        }
                    }.resume()
                    return
                }
                // No artwork case
                completion((trackName, artistName, albumName, nil, positionSeconds, durationSeconds))
                return
            }
        }
        // Could not get anything
        completion(nil)
    }

    /**
     * Fetches current playing information from Music app.
     * Returns tuple of (track, artist, album, artwork, position, duration) if successful.
     * - Returns: Tuple with info, or nil if not available.
     */
    private func getMusicInfo() -> (String, String, String, NSImage?, Double, Double)? {
        let script = """
        tell application \"Music\"
            set isRunning to true
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
                on error
                    set artData to ""
                end try
                return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, shuffleState, repeatState, artData}
            on error
                return {false, "Not Playing", "Unknown", "Unknown", 0, 0, false, false, ""}
            end try
        end tell
        """

        if let output = runAppleScript(script) {
            let cleaned = output
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
            
            let components = cleaned.components(separatedBy: ", ")

            if components.count >= 9 {
                let trackName = components[1].trimmingCharacters(in: .punctuationCharacters)
                let artistName = components[2].trimmingCharacters(in: .punctuationCharacters)
                let albumName = components[3].trimmingCharacters(in: .punctuationCharacters)
                let positionSeconds = Double(components[4]) ?? 0.0
                let durationSeconds = Double(components[5]) ?? 0.0
                let artDataRaw = components[8]

                var artworkImage: NSImage? = nil
                if artDataRaw != "\"\"" {
                    // Clean the base64 string
                    let cleanedData = artDataRaw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    if let data = Data(base64Encoded: cleanedData) {
                        artworkImage = NSImage(data: data)
                    }
                }

                return (trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds)
            }
        }

        return nil
    }
    /**
     * Extracts the dominant color from an image for UI theming.
     * Ensures minimum brightness for visibility.
     * - Parameter image: The NSImage to analyze.
     * - Returns: The dominant NSColor, or nil if extraction fails.
     */
    private func getDominantColor(from image: NSImage) -> NSColor? {
        guard let tiffData = image.tiffRepresentation,
            let ciImage = CIImage(data: tiffData) else { return nil }

        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(x: 0, y: 0, z: ciImage.extent.width, w: ciImage.extent.height)
        ])

        guard let outputImage = filter?.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8, colorSpace: nil
        )

        var red = CGFloat(bitmap[0]) / 255.0
        var green = CGFloat(bitmap[1]) / 255.0
        var blue = CGFloat(bitmap[2]) / 255.0
        let alpha = CGFloat(bitmap[3]) / 255.0

        // Calculate brightness as the average of RGB values
        let brightness = (red + green + blue) / 3.0 * 255.0

        if brightness < 128 {
            // Scale the brightness to reach 128
            let scale = 128.0 / brightness

            red = min(red * CGFloat(scale), 1.0)
            green = min(green * CGFloat(scale), 1.0)
            blue = min(blue * CGFloat(scale), 1.0)
        }

        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
// End of AppleScriptMusicController.swift
