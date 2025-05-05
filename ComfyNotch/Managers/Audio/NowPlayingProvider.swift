//
//  NowPlayingProvider.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import SwiftUI

/// Protocol defining the interface for a provider that supplies now playing information and playback controls.
/// Implementations should provide mechanisms to fetch current media info and control playback actions.
protocol NowPlayingProvider {
    /// Checks if the provider is available for use (e.g., required APIs or services are accessible).
    /// - Returns: `true` if the provider can be used, otherwise `false`.
    func isAvailable() -> Bool
    
    /// Fetches the current now playing information asynchronously.
    /// - Parameter completion: Closure called with a `Bool` indicating success or failure.
    func getNowPlayingInfo(completion: @escaping (Bool)->Void)
    
    /// Skips to the previous track in the playback queue.
    func playPreviousTrack() -> Void
    /// Skips to the next track in the playback queue.
    func playNextTrack() -> Void
    /// Toggles between play and pause states for the current media.
    func togglePlayPause() -> Void
    /// Seeks playback to a specific time within the current track.
    /// - Parameter time: The time (in seconds) to seek to.
    func playAtTime(to time: Double) -> Void
}

extension NowPlayingProvider {
    /// Extracts the dominant color from an image, ensuring a minimum brightness for visibility.
    /// This can be used to theme UI elements based on album artwork or other images.
    /// - Parameter image: The `NSImage` to analyze.
    /// - Returns: The dominant `NSColor`, or `nil` if extraction fails.
    func getDominantColor(from image: NSImage) -> NSColor? {
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
}
