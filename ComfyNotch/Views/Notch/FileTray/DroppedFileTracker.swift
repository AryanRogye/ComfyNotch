//
//  DroppedFileTracker.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/5/25.
//

import SwiftUI
import UniformTypeIdentifiers
import ImageIO

struct ByteFormatter {
    static func format(bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct FileInfo {
    let name: String
    let realType: String
    let mimeType: String?
    let sizeInKB: Int
    let dimensions: String?
    let creationDate: Date?
    let icon: NSImage
    
    init(name: String = "",
         realType: String = "",
         mimeType: String? = nil,
         sizeInKB: Int = 0,
         dimensions: String? = nil,
         creationDate: Date? = nil,
         icon: NSImage = NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)!) {
        self.name = name
        self.realType = realType
        self.mimeType = mimeType
        self.sizeInKB = sizeInKB
        self.dimensions = dimensions
        self.creationDate = creationDate
        self.icon = icon
    }
}

class DroppedFileTracker {
    static let shared = DroppedFileTracker()
    
    func extractFileInfo(from url: URL) -> FileInfo? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        let name = url.lastPathComponent
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let sizeInKB = (attributes?[.size] as? Int ?? 0) / 1024
        let creationDate = attributes?[.creationDate] as? Date
        
        let fileExtension = url.pathExtension.lowercased()
        var realType = fileExtension.uppercased()
        var mimeType: String? = nil
        var dimensions: String? = nil
        
        if let utType = UTType(filenameExtension: fileExtension) {
            realType = utType.localizedDescription ?? utType.identifier
            mimeType = utType.preferredMIMEType
        }
        
        // Image dimensions (only if it's a supported image)
        if UTType(filenameExtension: fileExtension)?.conforms(to: .image) == true {
            if let data = try? Data(contentsOf: url),
               let source = CGImageSourceCreateWithData(data as CFData, nil),
               let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
               let width = props[kCGImagePropertyPixelWidth],
               let height = props[kCGImagePropertyPixelHeight] {
                dimensions = "\(width) x \(height)"
            }
        }
        
        return FileInfo(
            name: name,
            realType: realType,
            mimeType: mimeType,
            sizeInKB: sizeInKB,
            dimensions: dimensions,
            creationDate: creationDate,
            icon: icon
        )
    }
}
