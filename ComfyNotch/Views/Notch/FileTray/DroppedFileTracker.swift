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
}
