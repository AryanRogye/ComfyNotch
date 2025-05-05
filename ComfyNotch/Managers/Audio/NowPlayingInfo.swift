
import SwiftUI

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
