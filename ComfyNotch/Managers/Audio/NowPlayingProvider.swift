//
//  NowPlayingProvider.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import SwiftUI
import Accelerate
import Foundation

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
    /**
     * Extracts the dominant color from an image for UI theming.
     * Ensures minimum brightness for visibility.
     * - Parameter image: The NSImage to analyze.
     * - Returns: The dominant NSColor, or nil if extraction fails.
     */
    public func getDominantColor(from image: NSImage) -> NSColor? {
        debugLog("Called getDominantColor")
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // Use vImage for fast resizing (part of Accelerate framework)
        let targetSize = CGSize(width: 1, height: 1)
        
        guard let resized = resizeImageWithVImage(cgImage, to: targetSize) else {
            return nil
        }
        
        // Direct pixel access - much faster than CGContext
        guard let pixelData = resized.dataProvider?.data,
              let bytes = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        
        // Extract RGBA values (assuming RGBA format)
        let red = CGFloat(bytes[0]) / 255.0
        let green = CGFloat(bytes[1]) / 255.0
        let blue = CGFloat(bytes[2]) / 255.0
        let alpha = CGFloat(bytes[3]) / 255.0
        
        // Apply brightness adjustment
        return adjustBrightness(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     * Ultra-fast image resizing using vImage (Accelerate framework)
     */
    private func resizeImageWithVImage(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Define the format
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        // Source buffer
        var sourceBuffer = vImage_Buffer()
        var destBuffer = vImage_Buffer()
        
        // Init source buffer
        guard vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }
        
        destBuffer.width = vImagePixelCount(width)
        destBuffer.height = vImagePixelCount(height)
        destBuffer.rowBytes = width * 4
        destBuffer.data = malloc(height * width * 4)
        
        // Resize
        let error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        
        free(sourceBuffer.data)
        
        guard error == kvImageNoError else {
            free(destBuffer.data)
            return nil
        }
        
        // Make image
        let context = CGContext(
            data: destBuffer.data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: destBuffer.rowBytes,
            space: format.colorSpace.takeRetainedValue(),
            bitmapInfo: format.bitmapInfo.rawValue
        )
        
        let result = context?.makeImage()
        free(destBuffer.data)
        return result
    }
    
    private func adjustBrightness(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> NSColor {
        var adjustedRed = red
        var adjustedGreen = green
        var adjustedBlue = blue
        
        let brightness = (red + green + blue) / 3.0
        
        if brightness < 0.5 { // 128/255 ≈ 0.5
            let scale = 0.5 / brightness
            adjustedRed = min(red * scale, 1.0)
            adjustedGreen = min(green * scale, 1.0)
            adjustedBlue = min(blue * scale, 1.0)
        }
        
        return NSColor(red: adjustedRed, green: adjustedGreen, blue: adjustedBlue, alpha: alpha)
    }}
