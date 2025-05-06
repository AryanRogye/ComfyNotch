//
//  DroppedFileTracker.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/5/25.
//

import SwiftUI
import CryptoKit

class DroppedFileTracker {
    static let shared = DroppedFileTracker()
    
    private var fileHashes: Set<String> = []
    private let queue = DispatchQueue(label: "com.app.filetracker", attributes: .concurrent)
    
    func isNewFile(url: URL) -> Bool {
        if let hash = fileHash(url: url) {
            return isNewHash(hash)
        }
        return true
    }
    
    func isNewData(data: Data) -> Bool {
        let hash = dataHash(data: data)
        return isNewHash(hash)
    }
    
    func registerFile(url: URL) {
        if let hash = fileHash(url: url) {
            registerHash(hash)
        }
    }
    
    func registerData(data: Data) {
        let hash = dataHash(data: data)
        registerHash(hash)
    }
    
    private func isNewHash(_ hash: String) -> Bool {
        var isNew = false
        queue.sync {
            isNew = !fileHashes.contains(hash)
        }
        return isNew
    }
    
    private func registerHash(_ hash: String) {
        queue.async(flags: .barrier) {
            self.fileHashes.insert(hash)
        }
    }
    
    func dataHash(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    func fileHash(url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return dataHash(data: data)
    }
}
