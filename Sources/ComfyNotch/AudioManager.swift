import AppKit
import MediaPlayer

class AudioManager {

    static let shared = AudioManager()

    var currentSongText: String = "Nothing Currently Playing"

    private init() {}

    func playPreviousTrack() {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 5) // 0 = Previous Track
    }
    
    func playNextTrack() {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 4) // 1 = Next Track
    }
    
    func togglePlayPause() {
        sendCommand(command: "MRMediaRemoteSendCommand", commandType: 2) // 2 = Play/Pause Toggle
    }

    /** 
     *
     * Get the current song playing in any media player (iTunes, Spotify, etc.)
     * will return "Nothing Currently Playing" if no song is playing but if theres a
     * error it will return "Error: \(error)"
     *
     **/
    func getNowPlayingInfo() -> Void {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else { 
            print("Failed to load MediaRemote framework")
            return 
        }

        guard let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
            print("Failed to get MRMediaRemoteGetNowPlayingInfo function pointer")
            return 
        }

        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { (info) in
            if let info = info {
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown Artist"
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Unknown Title"
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "Unknown Album"
                
                self.currentSongText = "\(artist) - \(title) [\(album)]"

                // Update UIManager's textField immediately
                DispatchQueue.main.async {
                    UIManager.shared.currentSongText = self.currentSongText
                    UIManager.shared.currentSongTextField?.stringValue = self.currentSongText
                }

                if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
                    let artworkImage = NSImage(data: artworkData) {
                    
                    DispatchQueue.main.async {
                        UIManager.shared.albumArtImage?.image = artworkImage
                        ScrollManager.shared.updatePanelState(for: UIManager.shared.panel.frame.height)
                    }
                }

            } else {
                self.currentSongText = "Nothing Currently Playing"
                DispatchQueue.main.async {
                    UIManager.shared.currentSongText = self.currentSongText
                    UIManager.shared.currentSongTextField?.stringValue = self.currentSongText
                }
            }
        }
    }

    private func sendCommand(command: String, commandType: Int) {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else { 
            print("Failed to load MediaRemote framework")
            return 
        }

        guard let pointer = CFBundleGetFunctionPointerForName(bundle, command as CFString) else {
            print("Failed to get \(command) function pointer")
            return 
        }

        typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, Any?, Int) -> Void
        let MRMediaRemoteSendCommand = unsafeBitCast(pointer, to: MRMediaRemoteSendCommandFunction.self)
        
        // Send the command
        MRMediaRemoteSendCommand(commandType, nil, 0)
    }

    func startMediaTimer() {
        self.getNowPlayingInfo()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.getNowPlayingInfo()
        }
        RunLoop.current.add(timer, forMode: .common)
    }

}
