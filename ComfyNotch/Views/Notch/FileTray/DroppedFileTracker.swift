//
//  DroppedFileTracker.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/5/25.
//

import SwiftUI
import CryptoKit
import UniformTypeIdentifiers
import OSLog
import UniformTypeIdentifiers
import ImageIO

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
         icon: NSImage = NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)!
    ) {
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
    
    private var fileHashes: Set<String> = []
    private let queue = DispatchQueue(label: "com.app.filetracker", attributes: .concurrent)
    
    func quickHash(url: URL) -> (UInt64, Data)? {
        guard let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attr[.size] as? UInt64,
              let handle = try? FileHandle(forReadingFrom: url) else { return nil }

        defer { try? handle.close() }

        let slice = try? handle.read(upToCount: 64 * 1024) ?? Data()
        let digest = SHA256.hash(data: slice ?? Data())
        return (size, Data(digest))
    }
    
    /// Check if the file is new by hashing + checking set
    func isNewFile(size: UInt64, hash: Data) -> Bool {
        let key = "\(size)-\(hash.base64EncodedString())"
        var isNew = false
        
        queue.sync {
            isNew = !fileHashes.contains(key)
        }
        
        return isNew
    }
    /// Register a file after accepting it
    func registerFile(size: UInt64, hash: Data, url: URL) {
        let key = "\(size)-\(hash.base64EncodedString())"

        queue.async(flags: .barrier) {
            self.fileHashes.insert(key)
        }

        // Optional: store the URL somewhere if you want to access file names later
        debugLog("📥 Registered file: \(url.lastPathComponent)")
    }

    /// Reset all tracked files (e.g. on session end)
    func reset() {
        queue.async(flags: .barrier) {
            self.fileHashes.removeAll()
        }
        debugLog("♻️ Dropped file tracker reset")
    }
    
    func detectRealFileType(from url: URL) -> UTType? {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return nil
        }
        return type
    }
    
    func extractFileInfo(from url: URL) -> FileInfo? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        // File name
        let name = url.lastPathComponent
        
        // File icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        // File size & creation date
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let sizeInKB = (attributes?[.size] as? Int ?? 0) / 1024
        let creationDate = attributes?[.creationDate] as? Date
        
        // Image metadata
        let data = try? Data(contentsOf: url)
        var realType = "Unknown"
        var mimeType: String?
        var dimensions: String?
        
        if let data = data,
           let source = CGImageSourceCreateWithData(data as CFData, nil),
           let type = CGImageSourceGetType(source),
           let utType = UTType(type as String) {
            
            realType = utType.localizedDescription ?? utType.identifier
            mimeType = utType.preferredMIMEType
            
            if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
               let width = props[kCGImagePropertyPixelWidth],
               let height = props[kCGImagePropertyPixelHeight] {
                dimensions = "\(width) x \(height)"
            }
        }
        
        if realType == "Unknown" {
            if let data = data {
                let header = data.prefix(4)
                if header.starts(with: [0x25, 0x50, 0x44, 0x46]) { // "%PDF"
                    realType = "PDF Document"
                    mimeType = "application/pdf"
                }
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
