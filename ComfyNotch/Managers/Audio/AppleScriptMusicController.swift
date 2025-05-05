//
//  FallbackNowPlayingProvider.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import Foundation
import SwiftUI

class AppleScriptMusicController: NowPlayingProvider {

    @ObservedObject var nowPlayingInfo: NowPlayingInfo

    init(nowPlayingInfo: NowPlayingInfo) {
        self.nowPlayingInfo = nowPlayingInfo
    }

    /// Function will always return true cuz this is a
    /// fallback if the PrivateAPI is not working or something
    /// goes wrong
    func isAvailable() -> Bool {
        true
    }
    
    func getNowPlayingInfo() -> Void {
        if !isSpotifyPlaying() && !isAppleMusicPlaying() {
            /// If Nethier Spotify nor Apple Music is playing
            /// Clear the now playing info
            clearNowPlaying()
        } else if isSpotifyPlaying() {
            /// If Spotify is playing, get the info from Spotify
            getSpotifyInfo { info in
                if let info = info {
                    self.updateNowPlaying(with: info)
                } else if self.isAppleMusicPlaying(), let musicInfo = self.getMusicInfo() {
                    /// If the Data we got back from Spotify is nil then
                    /// we try to get the info from Apple Music
                    self.updateNowPlaying(with: musicInfo)
                } else {
                    /// If both are nil, clear the now playing info
                    self.clearNowPlaying()
                }
            }
        }
    }
    
    /// Actions
    func playPreviousTrack() -> Void {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    previous track
                end tell
            """) {}
        } else if isAppleMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    previous track
                end tell
            """) {}
        } else {
            /// Do Nothing
        }
    }
    func playNextTrack() -> Void {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    next track
                end tell
            """) {}
        } else if isAppleMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    next track
                end tell
            """) {}
        } else {
            /// Do Nothing
        }
    }
    func togglePlayPause() -> Void {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    playpause
                end tell
            """) {}
        } else if isAppleMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    playpause
                end tell
            """) {}
        } else {
            /// Do Nothing
        }
    }
    func playAtTime(to time: Double) -> Void {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    set player position to \(time)
                end tell
            """) {}
        } else if isAppleMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    set player position to \(time)
                end tell
            """) {}
            
        } else {
            // Do Nothing
        }
    }




    /// -- Mark: Internal Functions
    private func isSpotifyPlaying() -> Bool {
        return isAppRunning("Spotify")
    }
    private func isAppleMusicPlaying() -> Bool {
        return isAppRunning("Music")
    }
    
    /// Function to check if a specific app is running
    private func isAppRunning(_ appName: String) -> Bool {
        let script = """
        tell application "System Events"
            set isRunning to (name of processes) contains "\(appName)"
        end tell
        return isRunning
        """
        if let output = runAppleScript(script) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
        }
        return false
    }

    /// Executes an AppleScript and returns the result as a string.
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
    /// Function to clear the now playing info
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
     * Returns tuple of (track, artist, album, artwork) if successful.
     */
    private func getSpotifyInfo(completion: @escaping ((String, String, String, NSImage?, Double, Double)?) -> Void) {
        let script = """
        tell application "Spotify"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set artworkURL to artwork url of current track
                set currentTime to player position
                set trackDuration to (duration of current track) / 1000
                return trackName & " - " & artistName & " - " & albumName & " - " & artworkURL & " - " & currentTime & " - " & trackDuration
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
                    // ✅ Fetch artwork asynchronously
                    URLSession.shared.dataTask(with: artworkURL) { data, response, error in
                        var artworkImage: NSImage? = nil
                        if let data = data {
                            artworkImage = NSImage(data: data)
                        }
                        // 🔥 Call completion handler back on MAIN thread
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
     * Returns tuple of (track, artist, album, artwork) if successful.
     */
    private func getMusicInfo() -> (String, String, String, NSImage?, Double, Double)? {
        let script = """
        tell application "Music"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set currentTime to player position
                set duration to duration of current track
                try
                    if (count of artworks of current track) > 0 then
                        set theArtwork to artwork 1 of current track
                        if class of theArtwork is artwork then
                            set artworkData to data of theArtwork
                            set artworkPath to ((path to temporary items as text) & "currentArtwork.jpg")
                            set artworkFile to open for access file artworkPath with write permission
                            set eof of artworkFile to 0
                            write artworkData to artworkFile
                            close access artworkFile
                            return trackName & " ||| " & artistName & " ||| " & albumName & " ||| " & artworkPath & " ||| " & currentTime & " ||| " & duration
                        end if
                    end if
                end try
                return trackName & " ||| " & artistName & " ||| " & albumName & " ||| NoArtwork ||| " & currentTime & " ||| " & duration
            end if
        end tell
        """

        if let output = runAppleScript(script) {
            let components = output.components(separatedBy: " ||| ")
            if components.count == 6 {
                let trackName = components[0]
                let artistName = components[1]
                let albumName = components[2]
                let artworkPath = components[3]
                let positionSeconds = Double(components[4]) ?? 0.0
                let durationSeconds = Double(components[5]) ?? 0.0

                var artworkImage: NSImage?

                if artworkPath != "NoArtwork", let image = NSImage(contentsOfFile: artworkPath) {
                    artworkImage = image
                }

                return (trackName, artistName, albumName, artworkImage, positionSeconds, durationSeconds)
            }
        }
        return nil
    }
    /**
     * Extracts the dominant color from an image.
     * Ensures minimum brightness for visibility.
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
