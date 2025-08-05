import AppKit

/**
 * AudioManager provides a unified interface for managing and controlling media playback across Spotify and Apple Music.
 *
 * Responsibilities:
 * - Tracks and updates current media playback information (track, artist, album, artwork, playback state)
 * - Integrates with both MediaRemote (private API) and AppleScript for robust provider fallback
 * - Exposes playback controls (play/pause, next, previous, seek)
 * - Periodically refreshes media info using a timer
 * - Notifies observers of changes via published properties and callbacks
 *
 * Usage:
 * Use AudioManager.shared to access the singleton instance. Observe nowPlayingInfo for updates.
 */
class AudioManager: ObservableObject {
    /// Singleton instance for global access
    static let shared = AudioManager()

    /// Published info about the currently playing media
    @Published var nowPlayingInfo: NowPlayingInfo = NowPlayingInfo()

    /// Controller for AppleScript-based music control (fallback)
    lazy var appleScriptMusicController: AppleScriptMusicController = {
        AppleScriptMusicController(nowPlayingInfo: self.nowPlayingInfo)
    }()
    /// Controller for MediaRemote-based music control (primary)
    lazy var mediaRemoteMusicController: MediaRemoteMusicController = {
        MediaRemoteMusicController(nowPlayingInfo: self.nowPlayingInfo)
    }()
    
    private var settings: SettingsModel = .shared

    private var timer: Timer?
    /// Optional callback invoked when nowPlayingInfo is updated
    var onNowPlayingInfoUpdated: (() -> Void)?
    
    private(set) var lastUsedProvider: MusicController = .spotify_music
    
    /**
     * Initializes the AudioManager and starts periodic media info updates.
     * Use the shared instance; direct initialization is private.
     */
    private init() {
        startMediaTimer()
    }

    /**
     * Fetches and updates the current playing media information.
     * Tries MediaRemote (Spotify/Apple Music) first, falls back to AppleScript if needed.
     */
    func getNowPlayingInfo(completion: @escaping (Bool) -> Void) {
        /// Settings will default to the media remote
        /// but its up to the user what they want to use
        if settings.musicController == .mediaRemote {
            fallbackNowPlaying()
        } else if settings.musicController == .spotify_music {
            DispatchQueue.global(qos: .utility).async {
                self.appleScriptMusicController.getNowPlayingInfo { _ in }
                self.lastUsedProvider = .spotify_music
            }
        } else {
            /// if neither works then we use this
            fallbackNowPlaying()
        }
    }
    
    private func fallbackNowPlaying() {
        if mediaRemoteMusicController.isAvailable() {
            mediaRemoteMusicController.getNowPlayingInfo { success in
                guard success else {
                    self.lastUsedProvider = .spotify_music
                    self.appleScriptMusicController.getNowPlayingInfo { _ in }
                    return
                }
                
                self.lastUsedProvider = .mediaRemote
            }
        } else {
            DispatchQueue.global(qos: .utility).async {
                self.lastUsedProvider = .spotify_music
                self.appleScriptMusicController.getNowPlayingInfo { _ in }
            }
        }
    }

    /**
     * Starts a timer to periodically refresh media information (every second).
     * Timer runs in the common run loop mode.
     */
    func startMediaTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.getNowPlayingInfo { _ in }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /**
     * Stops the periodic media info update timer.
     */
    func stopMediaTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Playback Controls

    /**
     * Skips to the previous track in the current provider.
     * Checks which provider is active before sending the command.
     */
    func playPreviousTrack() {
        
        if self.lastUsedProvider == .mediaRemote {
            mediaRemoteMusicController.playPreviousTrack()
        } else {
            appleScriptMusicController.playPreviousTrack()
        }
    }

    /**
     * Skips to the next track in the current provider.
     */
    func playNextTrack() {
        if self.lastUsedProvider == .mediaRemote {
            mediaRemoteMusicController.playNextTrack()
        } else {
            appleScriptMusicController.playNextTrack()
        }
    }

    /**
     * Toggles play/pause state for the current provider.
     */
    func togglePlayPause() {
        if self.lastUsedProvider == .mediaRemote {
            mediaRemoteMusicController.togglePlayPause()
        } else {
            appleScriptMusicController.togglePlayPause()
        }
    }

    /**
     * Seeks to a specific time (in seconds) in the current track.
     * @param time The position (in seconds) to seek to.
     */
    func playAtTime(to time: Double) {
        if self.lastUsedProvider == .mediaRemote {
            mediaRemoteMusicController.playAtTime(to: time)
        } else {
            appleScriptMusicController.playAtTime(to: time)
        }
    }

    /**
     * Opens the currently active music provider (Spotify or Music app).
     * If neither is active, does nothing.
     */
    func openProvider() {
        if appleScriptMusicController.isAvailable() {
            let appPath = "/Applications/"
            if appleScriptMusicController.isSpotifyPlaying() {
                if FileManager.default.fileExists(atPath: appPath + "Spotify.app") {
                    let appURL = URL(fileURLWithPath: appPath + "Spotify.app")
                    NSWorkspace.shared.openApplication(at: appURL,
                                                       configuration: NSWorkspace.OpenConfiguration(),
                                                       completionHandler: nil)
                    UIManager.shared.applyOpeningLayout()
                    ScrollManager.shared.closeFull()
                    return
                } else {
                    debugLog("Spotify App Couldnt Be Opened", from: .musicError)
                }
            } else if appleScriptMusicController.isAppleMusicPlaying() {
                if FileManager.default.fileExists(atPath: appPath + "Music.app") {
                    let appURL = URL(fileURLWithPath: appPath + "Music.app")
                    NSWorkspace.shared.openApplication(at: appURL,
                                                       configuration: NSWorkspace.OpenConfiguration(),
                                                       completionHandler: nil)
                    UIManager.shared.applyOpeningLayout()
                    ScrollManager.shared.closeFull()
                    return
                } else {
                    debugLog("Music App Couldnt Be Opened", from: .musicError)
                }
            } else {
                debugLog("No Provider Currently Playing", from: .aSController)
            }
        }
    }
}
