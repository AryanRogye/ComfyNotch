
import SwiftUI

/// Stores and publishes information about the currently playing audio track.
/// This class is observed by UI components to reflect real-time playback changes.
class NowPlayingInfo: ObservableObject {
    /// The name of the currently playing track. Defaults to "No Song Playing" if nothing is playing.
    @Published var trackName: String = "No Song Playing"
    /// The name of the artist for the current track. Defaults to "Unknown Artist".
    @Published var artistName: String = "Unknown Artist"
    /// The name of the album for the current track. Defaults to "Unknown Album".
    @Published var albumName: String = "Unknown Album"
    /// The artwork image associated with the current track, if available.
    @Published var artworkImage: NSImage? = nil
    /// The dominant color extracted from the artwork image, used for UI theming. Defaults to white.
    @Published var dominantColor: NSColor = .white
    /// The current playback position in seconds.
    @Published var positionSeconds: Double = 0.0
    /// The total duration of the current track in seconds.
    @Published var durationSeconds: Double = 0.0
    /// Indicates whether the track is currently playing.
    @Published var isPlaying: Bool = false
    /// The music provider (e.g., Apple Music, Spotify) currently in use.
    @Published var musicProvider: MusicProvider = .none
}
