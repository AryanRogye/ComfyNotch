import AppKit
import MediaPlayer

class AudioManager {

    static let shared = AudioManager()

    @Published var currentSongText: String = "No Song Playing"
    @Published var currentArtistText: String = "Unknown Artist"
    @Published var currentAlbumText: String = "Unknown Album"
    @Published var currentArtworkImage: NSImage? = nil

    private var timer: Timer?
    var onNowPlayingInfoUpdated: (() -> Void)?


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
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Nothing Currently Playing"
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "Unknown Album"
                
                self.currentSongText = title
                self.currentArtistText = artist
                self.currentAlbumText = album

                // print("Current Song: \(self.currentSongText) by \(self.currentArtistText) from \(self.currentAlbumText)")
                
                if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
                   let artworkImage = NSImage(data: artworkData) {
                    self.currentArtworkImage = artworkImage
                }

                // Call the callback to notify the UI about the update
                self.onNowPlayingInfoUpdated?()
            } else {
                self.currentSongText = "No Song Playing"
                self.currentArtistText = "Unknown Artist"
                self.currentAlbumText = "Unknown Album"
                self.currentArtworkImage = nil
                
                // Notify about the update
                self.onNowPlayingInfoUpdated?()
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
        self.getNowPlayingInfo()  // Initial call

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
}
