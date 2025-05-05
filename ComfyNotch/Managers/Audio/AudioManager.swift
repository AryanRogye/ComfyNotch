import AppKit

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
    lazy var mediaRemoteMusicController: MediaRemoteMusicController = {
        MediaRemoteMusicController(nowPlayingInfo: self.nowPlayingInfo)
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
        /// Helper to call functions because some information
        /// Gathering might fail
        if mediaRemoteMusicController.isAvailable() {
            print("Is Available")
            mediaRemoteMusicController.getNowPlayingInfo { success in
                // 2) if it failed to return *usable* data, fall back:
                if !success {
                    self.appleScriptMusicController.getNowPlayingInfo { _ in }
                }
            }
        } else {
            print("Getting Music Info from AppleScript")
            appleScriptMusicController.getNowPlayingInfo { _ in }
        }
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
    
    func openProvider() {
        if appleScriptMusicController.isAvailable() {
            debugLog("Called Top Open Provded")
            let appPath = "/Applications/"
            if appleScriptMusicController.isSpotifyPlaying() {
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
            } else if appleScriptMusicController.isAppleMusicPlaying() {
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
    }
}
