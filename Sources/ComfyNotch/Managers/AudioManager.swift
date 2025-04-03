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
}
