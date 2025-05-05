import AppKit
import MediaPlayer
import CoreImage

    public enum MusicProver {
        case none
        case apple_music
        case spotify
    }

class NowPlayingInfo: ObservableObject {
    @Published var trackName: String = "No Song Playing"
    @Published var artistName: String = "Unknown Artist"
    @Published var albumName: String = "Unknown Album"
    @Published var artworkImage: NSImage? = nil
    @Published var dominantColor: NSColor = .white
    @Published var positionSeconds: Double = 0.0
    @Published var durationSeconds: Double = 0.0
    @Published var isPlaying: Bool = false
    @Published var musicProvider: MusicProver = .none
}


// class MediaRemoteFrameworkWrapper: NowPlayingProvider {
//     func getNowPlayingInfo() {
//
//     }
//
//     /// --Mark: Internal API's
//     func isAvailable() -> Bool {
//         let frameworkURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
//         guard let bundle = CFBundleCreate(kCFAllocatorDefault, frameworkURL as CFURL) else {
//             print("❌ MediaRemote.framework not found.")
//             return false
//         }
//
//         let fn = "MRMediaRemoteGetNowPlayingInfo" as CFString
//         let hasFunc = CFBundleGetFunctionPointerForName(bundle, fn)
//
//         if hasFunc != nil {
//             print("✅ MediaRemote is available and MRMediaRemoteGetNowPlayingInfo is loaded.")
//             return true
//         } else {
//             print("⚠️ MediaRemote is present, but GetNowPlayingInfo function is missing.")
//             return false
//         }
//     }
//
//     func playPreviousTrack() -> Void {
//         sendCommand(command: "MRMediaRemoteSendCommand", commandType: 5) // 0 = Previous Track
//     }
//     func playNextTrack() -> Void {
//         sendCommand(command: "MRMediaRemoteSendCommand", commandType: 4) // 1 = Next Track
//     }
//     func togglePlayPause() -> Void {
//         sendCommand(command: "MRMediaRemoteSendCommand", commandType: 2) // 2 = Play/Pause Toggle
//     }
//     func playAtTime() -> Void {
//
//     }
//
//     private func sendCommand(command: String, commandType: Int) {
//         guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
//             debugLog("Failed to load MediaRemote framework")
//             return
//         }
//
//         guard let pointer = CFBundleGetFunctionPointerForName(bundle, command as CFString) else {
//             debugLog("Failed to get \(command) function pointer")
//             return
//         }
//
//         typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, Any?, Int) -> Void
//         let MRMediaRemoteSendCommand = unsafeBitCast(pointer, to: MRMediaRemoteSendCommandFunction.self)
//
//         // Send the command
//         MRMediaRemoteSendCommand(commandType, nil, 0)
//     }
// }

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
    static let shared = AudioManager()
    
    @Published var nowPlayingInfo: NowPlayingInfo = NowPlayingInfo()

    lazy var appleScriptMusicController: AppleScriptMusicController = {
        AppleScriptMusicController(nowPlayingInfo: self.nowPlayingInfo)
    }()
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
        if isMediaRemoteAvailable() {
            if !usePrivateFrameworkMethods() {
                appleScriptMusicController.getNowPlayingInfo()
            }
        } else {
            print("Using Apple Music")
            appleScriptMusicController.getNowPlayingInfo()
        }
    }
    
    /// This can fail so thats why the failsafe is the
    /// useAppleScripts Method
    private func usePrivateFrameworkMethods() -> Bool {
        false
    }
    
    /**
     * Updates the current playing media information with provided data.
     * Also extracts and updates the dominant color from artwork.
     */
//    private func updateNowPlaying(with info: (String, String, String, NSImage?, Double, Double)) {
//        self.currentSongText = info.0
//        self.currentArtistText = info.1
//        self.currentAlbumText = info.2
//        self.currentArtworkImage = info.3
//        if let inf = info.3 {
////            self.dominantColor = self.getDominantColor(from: inf) ?? .white
//        }
//        self.currentSecondsSong = info.4
//        self.totalSecondsSong = info.5
//        self.onNowPlayingInfoUpdated?()
//    }
    
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
     * Media control methods.
     * instead of attempting to open, we check if either
     * spotify is open first, then music, do the action,
     * or do nothing
     */
    func playPreviousTrack() {
        appleScriptMusicController.playPreviousTrack()
    }
    
    func playNextTrack() {
        appleScriptMusicController.playNextTrack()
    }
    func togglePlayPause() {
        appleScriptMusicController.togglePlayPause()
    }
    
    func playAtTime(to time: Double) {
        appleScriptMusicController.playAtTime(to: time)
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
    
//    func MediaRemote_getNowPlayingInfo() -> Void {
//        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
//            debugLog("Failed to load MediaRemote framework")
//            return
//        }
//        
//        guard let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
//            debugLog("Failed to get MRMediaRemoteGetNowPlayingInfo function pointer")
//            return
//        }
//        
//        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
//        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
//        
//        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { (info) in
//            if let info = info {
//                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown Artist"
//                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Nothing Currently Playing"
//                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "Unknown Album"
//                
//                self.currentSongText = title
//                self.currentArtistText = artist
//                self.currentAlbumText = album
//                
//                // debugLog("Current Song: \(self.currentSongText) by \(self.currentArtistText) from \(self.currentAlbumText)")
//                
//                if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
//                   let artworkImage = NSImage(data: artworkData) {
//                    self.currentArtworkImage = artworkImage
////                    self.dominantColor = self.getDominantColor(from: artworkImage) ?? .white
//                }
//                
//                // Call the callback to notify the UI about the update
//                self.onNowPlayingInfoUpdated?()
//            } else {
//                self.currentSongText = "No Song Playing"
//                self.currentArtistText = "Unknown Artist"
//                self.currentAlbumText = "Unknown Album"
//                self.currentArtworkImage = nil
//                self.dominantColor = .white
//                
//                // Notify about the update
//                self.onNowPlayingInfoUpdated?()
//            }
//        }
//    }

    func openProvider() {
//        debugLog("Called Top Open Provded")
//        let appPath = "/Applications/"
//        if isSpotifyPlaying() {
//            debugLog("Opening Spotify")
//            if FileManager.default.fileExists(atPath: appPath + "Spotify.app") {
//                let appURL = URL(fileURLWithPath: appPath + "Spotify.app")
//                NSWorkspace.shared.openApplication(at: appURL,
//                                                   configuration: NSWorkspace.OpenConfiguration(),
//                                                   completionHandler: nil)
//                return
//            } else {
//                debugLog("Spotify App Couldnt Be Opened")
//            }
//        } else if isMusicPlaying() {
//            debugLog("Opening Music")
//            if FileManager.default.fileExists(atPath: appPath + "Music.app") {
//                let appURL = URL(fileURLWithPath: appPath + "Music.app")
//                NSWorkspace.shared.openApplication(at: appURL,
//                                                   configuration: NSWorkspace.OpenConfiguration(),
//                                                   completionHandler: nil)
//                return
//            } else {
//                debugLog("Music App Couldnt Be Opened")
//            }
//        } else {
//            /// Do Nothing
//        }
    }
    
    func isMediaRemoteAvailable() -> Bool {
        return false
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
