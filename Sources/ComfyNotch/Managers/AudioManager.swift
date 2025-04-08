import AppKit
import MediaPlayer
import CoreImage

/**
 * AudioManager handles media playback information and control across music applications.
 * Provides unified interface for Spotify and Apple Music integration.
 *
 * Key Features:
 * - Tracks current playing media information
 * - Manages artwork and dominant color extraction
 * - Provides playback controls
 * - Auto-updates media information
 */
class AudioManager {
    static let shared = AudioManager()

    /// Currently playing song title
    @Published var currentSongText: String = "No Song Playing"
    /// Current artist name
    @Published var currentArtistText: String = "Unknown Artist"
    /// Current album name
    @Published var currentAlbumText: String = "Unknown Album"
    /// Current album artwork
    @Published var currentArtworkImage: NSImage? = nil
    /// Dominant color extracted from artwork
    @Published var dominantColor: NSColor = .white

    private var timer: Timer?
    var onNowPlayingInfoUpdated: (() -> Void)?

    /**
     * Initializes the audio manager and starts the media update timer.
     */
    private init() {
        startMediaTimer()
    }

    /**
     * Fetches and updates current playing media information.
     * Checks Spotify first, then falls back to Music app if needed.
     */
    func getNowPlayingInfo() {
        if let spotifyInfo = getSpotifyInfo() {
            updateNowPlaying(with: spotifyInfo)
        } else if let musicInfo = getMusicInfo() {
            updateNowPlaying(with: musicInfo)
        } else {
            // Fallback if nothing is playing on Spotify or Music
            self.currentSongText = "No Song Playing"
            self.currentArtistText = "Unknown Artist"
            self.currentAlbumText = "Unknown Album"
            self.currentArtworkImage = nil
            self.dominantColor = .white
        }
        
        self.onNowPlayingInfoUpdated?()
    }

    /**
     * Updates the current playing media information with provided data.
     * Also extracts and updates the dominant color from artwork.
     */
    private func updateNowPlaying(with info: (String, String, String, NSImage?)) {
        self.currentSongText = info.0
        self.currentArtistText = info.1
        self.currentAlbumText = info.2
        self.currentArtworkImage = info.3
        if let inf = info.3 {
            self.dominantColor = self.getDominantColor(from: inf) ?? .white
        }
    }

    /**
     * Fetches current playing information from Spotify.
     * Returns tuple of (track, artist, album, artwork) if successful.
     */
    private func getSpotifyInfo() -> (String, String, String, NSImage?)? {
        let script = """
        tell application "Spotify"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set artworkURL to artwork url of current track
                return trackName & " - " & artistName & " - " & albumName & " - " & artworkURL
            end if
        end tell
        """
        
        if let output = runAppleScript(script) {
            let components = output.components(separatedBy: " - ")
            if components.count == 4 {
                let trackName = components[0]
                let artistName = components[1]
                let albumName = components[2]
                let artworkURLString = components[3]
                
                var artworkImage: NSImage? = nil
                
                if let artworkURL = URL(string: artworkURLString), let imageData = try? Data(contentsOf: artworkURL) {
                    artworkImage = NSImage(data: imageData)
                }
                
                return (trackName, artistName, albumName, artworkImage)
            }
        }
        return nil
    }

    /**
     * Fetches current playing information from Music app.
     * Returns tuple of (track, artist, album, artwork) if successful.
     */
    private func getMusicInfo() -> (String, String, String, NSImage?)? {
        let script = """
        tell application "Music"
            if player state is playing then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                try
                    set artworkData to data of artwork 1 of current track
                    set artworkPath to ((path to temporary items as text) & "currentArtwork.jpg")
                    set artworkFile to open for access file artworkPath with write permission
                    write artworkData to artworkFile
                    close access artworkFile
                    return trackName & " - " & artistName & " - " & albumName & " - " & artworkPath
                on error
                    return trackName & " - " & artistName & " - " & albumName & " - " & "NoArtwork"
                end try
            end if
        end tell
        """
        
        if let output = runAppleScript(script) {
            let components = output.components(separatedBy: " - ")
            if components.count == 4 {
                let trackName = components[0]
                let artistName = components[1]
                let albumName = components[2]
                let artworkPath = components[3]
                
                var artworkImage: NSImage? = nil
                
                if artworkPath != "NoArtwork", let image = NSImage(contentsOfFile: artworkPath) {
                    artworkImage = image
                }
                
                return (trackName, artistName, albumName, artworkImage)
            }
        }
        return nil
    }

    /**
     * Executes an AppleScript and returns the result as a string.
     */
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error).stringValue
            return output
        }
        return nil
    }

    /**
     * Starts the timer that periodically updates media information.
     * Timer runs every second in common run loop mode.
     */
    func startMediaTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.getNowPlayingInfo()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /**
     * Stops the media update timer.
     */
    func stopMediaTimer() {
        timer?.invalidate()
        timer = nil
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
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
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

    /**
     * Media control methods.
     * These methods attempt Spotify first, then fall back to Music app.
     */
    func playPreviousTrack() {
        if runAppleScript("""
            tell application "Spotify"
                previous track
            end tell
        """) == nil {
            let _ = runAppleScript("""
                tell application "Music"
                    previous track
                end tell
            """)
        }
    }
    
    func playNextTrack() {
        if runAppleScript("""
            tell application "Spotify"
                next track
            end tell
        """) == nil {
            let _ = runAppleScript("""
                tell application "Music"
                    next track
                end tell
            """)
        }
    }
    
    func togglePlayPause() {
        if runAppleScript("""
            tell application "Spotify"
                playpause
            end tell
        """) == nil {
            let _ = runAppleScript("""
                tell application "Music"
                    playpause
                end tell
            """)
        }
    }
}
