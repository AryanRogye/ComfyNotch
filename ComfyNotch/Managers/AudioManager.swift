import AppKit
import MediaPlayer
import CoreImage

protocol NowPlaingProvider {
    func isAvailable() -> Bool
    
    /// Actions
    func playPreviousTrack() -> Void
    func playNextTrack() -> Void
    func togglePlayPause() -> Void
    func playAtTime() -> Void
}

class AppleScriptWrapper : NowPlaingProvider {
    /// --Mark: Exposed API's
    /// --Mark: Internal API's

    /// Always is available
    func isAvailable() -> Bool {
        return true
    }
    func playPreviousTrack() -> Void {
        
    }
    func playNextTrack() -> Void {
        
    }
    func togglePlayPause() -> Void {
        
    }
    func playAtTime() -> Void {
        
    }
}

class MediaRemoteFrameworkWrapper: NowPlaingProvider {
    /// --Mark: Internal API's
    func isAvailable() -> Bool {
        let frameworkURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, frameworkURL as CFURL) else {
            print("❌ MediaRemote.framework not found.")
            return false
        }
        
        let fn = "MRMediaRemoteGetNowPlayingInfo" as CFString
        let hasFunc = CFBundleGetFunctionPointerForName(bundle, fn)
        
        if hasFunc != nil {
            print("✅ MediaRemote is available and MRMediaRemoteGetNowPlayingInfo is loaded.")
            return true
        } else {
            print("⚠️ MediaRemote is present, but GetNowPlayingInfo function is missing.")
            return false
        }
    }
    
    func playPreviousTrack() -> Void {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 5) // 0 = Previous Track
    }
    func playNextTrack() -> Void {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 4) // 1 = Next Track
    }
    func togglePlayPause() -> Void {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 2) // 2 = Play/Pause Toggle
    }
    func playAtTime() -> Void {
        
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
class AudioManager: ObservableObject {
    public enum MusicProver {
        case none
        case apple_music
        case spotify
    }
    
    static let shared = AudioManager()
    
    /// Currently playing song title
    @Published var currentSongText: String = "No Song Playing"
    /// Current artist name
    @Published var currentArtistText: String = "Unknown Artist"
    /// Current album name
    @Published var currentAlbumText: String = "Unknown Album"
    /// Current album artwork
    @Published var currentArtworkImage: NSImage?
    /// Dominant color extracted from artwork
    @Published var dominantColor: NSColor = .white
    /// Current Seconds The Audio is Playing
    @Published var currentSecondsSong: Double = 0.0
    /// Current Total Seconds of the Audio that is Playing
    @Published var totalSecondsSong: Double = 0.0
    /// What Provder the user is currently listening to
    @Published var musicProvider: MusicProver = .apple_music
    /// if is playing
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    var onNowPlayingInfoUpdated: (() -> Void)?
    
    /**
     * Initializes the audio manager and starts the media update timer.
     */
    private init() {
        startMediaTimer()
    }
    
    private func isSpotifyPlaying() -> Bool {
        return isAppRunning("Spotify")
    }
    private func isMusicPlaying() -> Bool {
        return isAppRunning("Music")
    }
    
    private func clearNowPlaying() {
        self.currentSongText = "No Song Playing"
        self.currentArtistText = "Unknown Artist"
        self.currentAlbumText = "Unknown Album"
        self.currentArtworkImage = nil
        self.dominantColor = .white
        self.isPlaying = false
    }
    
    /**
     * Fetches and updates current playing media information.
     * Checks Spotify first, then falls back to Music app if needed.
     */
    func getNowPlayingInfo() {
        if isMediaRemoteAvailable() {
            if !usePrivateFrameworkMethods() {
                useAppleScriptMethods()
            }
        } else {
            useAppleScriptMethods()
        }
    }
    
    /// This can fail so thats why the failsafe is the
    /// useAppleScripts Method
    private func usePrivateFrameworkMethods() -> Bool {
        true
    }
    
    private func useAppleScriptMethods() {
        /// If Private Framework isnt laoding
        if !isSpotifyPlaying() && !isMusicPlaying() {
            musicProvider = .none
            clearNowPlaying()
        } else if isSpotifyPlaying() {
            getSpotifyInfo { info in
                if let info = info {
                    self.updateNowPlaying(with: info)
                    self.musicProvider = .spotify
                } else if self.isMusicPlaying(), let musicInfo = self.getMusicInfo() {
                    self.updateNowPlaying(with: musicInfo)
                    self.musicProvider = .apple_music
                } else {
                    self.clearNowPlaying()
                    self.musicProvider = .none
                }
            }
        } else if isMusicPlaying() {
            if let musicInfo = self.getMusicInfo() {
                self.updateNowPlaying(with: musicInfo)
                self.musicProvider = .apple_music
            }
        }
    }
    
    /**
     * Updates the current playing media information with provided data.
     * Also extracts and updates the dominant color from artwork.
     */
    private func updateNowPlaying(with info: (String, String, String, NSImage?, Double, Double)) {
        self.currentSongText = info.0
        self.currentArtistText = info.1
        self.currentAlbumText = info.2
        self.currentArtworkImage = info.3
        if let inf = info.3 {
            self.dominantColor = self.getDominantColor(from: inf) ?? .white
        }
        self.currentSecondsSong = info.4
        self.totalSecondsSong = info.5
        self.onNowPlayingInfoUpdated?()
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
     * Executes an AppleScript and returns the result as a string.
     */
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
    
    
    /**
     * Media control methods.
     * instead of attempting to open, we check if either
     * spotify is open first, then music, do the action,
     * or do nothing
     */
    func playPreviousTrack() {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    previous track
                end tell
            """) {}
        } else if isMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    previous track
                end tell
            """) {}
        } else {
            /// Do Nothing
        }
    }
    
    func playNextTrack() {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    next track
                end tell
            """) {}
        } else if isMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    next track
                end tell
            """) {}
        } else {
            /// Do Nothing
        }
    }
    func togglePlayPause() {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    playpause
                end tell
            """) {}
        } else if isMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    playpause
                end tell
            """) {}
        } else {
            /// Do Nothing
        }
    }
    
    func playAtTime(to time: Double) {
        if isSpotifyPlaying() {
            if let _ = runAppleScript("""
                tell application "Spotify"
                    set player position to \(time)
                end tell
            """) {}
        } else if isMusicPlaying() {
            if let _ = runAppleScript("""
                tell application "Music"
                    set player position to \(time)
                end tell
            """) {}
            
        } else {
            // Do Nothing
        }
    }
    
        func MediaRemote_PlayPreviousTrack() {
            sendCommand(command: "MRMediaRemoteSendCommand", commandType: 5) // 0 = Previous Track
        }
         
        func MediaRemote_PlayNextTrack() {
            sendCommand(command: "MRMediaRemoteSendCommand", commandType: 4) // 1 = Next Track
        }
         
        func MediaRemote_TogglePlayPause() {
            sendCommand(command: "MRMediaRemoteSendCommand", commandType: 2) // 2 = Play/Pause Toggle
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
    
    func MediaRemote_getNowPlayingInfo() -> Void {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
            debugLog("Failed to load MediaRemote framework")
            return
        }
        
        guard let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
            debugLog("Failed to get MRMediaRemoteGetNowPlayingInfo function pointer")
            return
        }
        
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { (info) in
            if let info = info {
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown Artist"
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Nothing Currently Playing"
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "Unknown Album"
                
                self.currentSongText = title
                self.currentArtistText = artist
                self.currentAlbumText = album
                
                // debugLog("Current Song: \(self.currentSongText) by \(self.currentArtistText) from \(self.currentAlbumText)")
                
                if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
                   let artworkImage = NSImage(data: artworkData) {
                    self.currentArtworkImage = artworkImage
                    self.dominantColor = self.getDominantColor(from: artworkImage) ?? .white
                }
                
                // Call the callback to notify the UI about the update
                self.onNowPlayingInfoUpdated?()
            } else {
                self.currentSongText = "No Song Playing"
                self.currentArtistText = "Unknown Artist"
                self.currentAlbumText = "Unknown Album"
                self.currentArtworkImage = nil
                self.dominantColor = .white
                
                // Notify about the update
                self.onNowPlayingInfoUpdated?()
            }
        }
    }

    func openProvider() {
        debugLog("Called Top Open Provded")
        let appPath = "/Applications/"
        if isSpotifyPlaying() {
            debugLog("Opening Spotify")
            if FileManager.default.fileExists(atPath: appPath + "Spotify.app") {
                let appURL = URL(fileURLWithPath: appPath + "Spotify.app")
                NSWorkspace.shared.openApplication(at: appURL,
                                                   configuration: NSWorkspace.OpenConfiguration(),
                                                   completionHandler: nil)
                return
            } else {
                debugLog("Spotify App Couldnt Be Opened")
            }
        } else if isMusicPlaying() {
            debugLog("Opening Music")
            if FileManager.default.fileExists(atPath: appPath + "Music.app") {
                let appURL = URL(fileURLWithPath: appPath + "Music.app")
                NSWorkspace.shared.openApplication(at: appURL,
                                                   configuration: NSWorkspace.OpenConfiguration(),
                                                   completionHandler: nil)
                return
            } else {
                debugLog("Music App Couldnt Be Opened")
            }
        } else {
            /// Do Nothing
        }
    }
    
    func isMediaRemoteAvailable() -> Bool {
        let frameworkURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, frameworkURL as CFURL) else {
            print("❌ MediaRemote.framework not found.")
            return false
        }
        
        let fn = "MRMediaRemoteGetNowPlayingInfo" as CFString
        let hasFunc = CFBundleGetFunctionPointerForName(bundle, fn)
        
        if hasFunc != nil {
            print("✅ MediaRemote is available and MRMediaRemoteGetNowPlayingInfo is loaded.")
            return true
        } else {
            print("⚠️ MediaRemote is present, but GetNowPlayingInfo function is missing.")
            return false
        }
    }
}

//import AppKit
//import MediaPlayer
//import CoreImage
//
//class AudioManager {
//
//    static let shared = AudioManager()
//
//    @Published var currentSongText: String = "No Song Playing"
//    @Published var currentArtistText: String = "Unknown Artist"
//    @Published var currentAlbumText: String = "Unknown Album"
//    @Published var currentArtworkImage: NSImage? = nil
//    @Published var dominantColor: NSColor = .white
//
//    private var timer: Timer?
//    var onNowPlayingInfoUpdated: (() -> Void)?
//
//    private init() {}
//
//
//    /**
//     *
//     * Get the current song playing in any media player (iTunes, Spotify, etc.)
//     * will return "Nothing Currently Playing" if no song is playing but if theres a
//     * error it will return "Error: \(error)"
//     *
//     **/
//
//
//    func startMediaTimer() {
//        self.getNowPlayingInfo()  // Initial call
//
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            self?.getNowPlayingInfo()
//        }
//
//        RunLoop.main.add(timer!, forMode: .common)
//    }
//
//    func stopMediaTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//
//    private func getDominantColor(from image: NSImage) -> NSColor? {
//        guard let tiffData = image.tiffRepresentation,
//            let ciImage = CIImage(data: tiffData) else { return nil }
//
//        let filter = CIFilter(name: "CIAreaAverage", parameters: [
//            kCIInputImageKey: ciImage,
//            kCIInputExtentKey: CIVector(x: 0, y: 0, z: ciImage.extent.width, w: ciImage.extent.height)
//        ])
//
//        guard let outputImage = filter?.outputImage else { return nil }
//
//        var bitmap = [UInt8](repeating: 0, count: 4)
//        let context = CIContext()
//        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
//
//        var red = CGFloat(bitmap[0]) / 255.0
//        var green = CGFloat(bitmap[1]) / 255.0
//        var blue = CGFloat(bitmap[2]) / 255.0
//        let alpha = CGFloat(bitmap[3]) / 255.0
//
//        // Calculate brightness as the average of RGB values
//        let brightness = (red + green + blue) / 3.0 * 255.0
//
//        if brightness < 128 {
//            // Scale the brightness to reach 128
//            let scale = 128.0 / brightness
//
//            red = min(red * CGFloat(scale), 1.0)
//            green = min(green * CGFloat(scale), 1.0)
//            blue = min(blue * CGFloat(scale), 1.0)
//        }
//
//        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
//    }
//}
