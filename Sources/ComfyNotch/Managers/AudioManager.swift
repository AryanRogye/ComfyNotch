import AppKit
import MediaPlayer
import CoreImage

class AudioManager {

    static let shared = AudioManager()

    @Published var currentSongText: String = "No Song Playing"
    @Published var currentArtistText: String = "Unknown Artist"
    @Published var currentAlbumText: String = "Unknown Album"
    @Published var currentArtworkImage: NSImage? = nil
    @Published var dominantColor: NSColor = .white

    private var timer: Timer?
    var onNowPlayingInfoUpdated: (() -> Void)?

    private init() {
        startMediaTimer()
    }

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

    private func updateNowPlaying(with info: (String, String, String, NSImage?)) {
        self.currentSongText = info.0
        self.currentArtistText = info.1
        self.currentAlbumText = info.2
        self.currentArtworkImage = info.3
        self.dominantColor = self.getDominantColor(from: info.3) ?? .white
    }

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

    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error).stringValue
            return output
        }
        return nil
    }

    func startMediaTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.getNowPlayingInfo()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopMediaTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func getDominantColor(from image: NSImage?) -> NSColor? {
        guard let image = image,
              let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else { return nil }

        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(x: 0, y: 0, z: ciImage.extent.width, w: ciImage.extent.height)
        ])
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return NSColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: CGFloat(bitmap[3]) / 255.0)
    }

    func playPreviousTrack() {
        if runAppleScript("""
            tell application "Spotify"
                previous track
            end tell
        """) == nil {
            runAppleScript("""
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
            runAppleScript("""
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
            runAppleScript("""
                tell application "Music"
                    playpause
                end tell
            """)
        }
    }
}
