//
//  MessagesManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/27/25.
//

import SwiftUI
import SQLite
import Contacts

// MARK: - Internal Functions
extension MessagesManager {
    internal func formatDate(_ date: Int64) -> Date {
        /// Apple Holds Messages in nanoseconds since 2001
        let refDate = Date(timeIntervalSinceReferenceDate: 0) // 2001-01-01
        
        // If it's greater than a huge number, assume it's in nanoseconds
        let seconds: Double
        if date > 1_000_000_000_000 {
            seconds = Double(date) / 1_000_000_000
        } else {
            seconds = Double(date)
        }
        
        return refDate.addingTimeInterval(seconds)
    }
    
    internal func clearCurrentUserMessages() {
        self.currentUserMessages = []
    }
    
    /// Attempts to decode an `attributedBody` blob from Messages.db
    /// – Handles secure‑coded, legacy, and very‑old archives
    /// – Falls back to the first `.link` attribute if the string is empty
    ///
    /// - Parameter data:  The raw `attributedBody` column (may be `nil`)
    /// - Returns: A user‑visible string, or an empty string if nothing decodes.
    internal func formatAttributedBody(_ data: Data?) -> String {
        guard let data else { return "" }
        
        var attributed: NSAttributedString?
        var lastError: Error?
        
        // ① secure‑coding path  (modern archives)
        do {
            attributed = try NSKeyedUnarchiver
                .unarchivedObject(ofClass: NSAttributedString.self, from: data)
        } catch {
            lastError = error
        }
        
        // ② legacy top‑level path  (pre‑iOS‑14 emoji, etc.)
        if attributed == nil {
            do {
                attributed = try NSKeyedUnarchiver
                    .unarchiveTopLevelObjectWithData(data) as? NSAttributedString
            } catch {
                lastError = error
            }
        }
        
        // ③ very‑old archives: manual unarchiver
        if attributed == nil {
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                unarchiver.requiresSecureCoding = false
                attributed = unarchiver
                    .decodeObject(of: NSAttributedString.self,
                                  forKey: NSKeyedArchiveRootObjectKey)
                unarchiver.finishDecoding()
            } catch {
                lastError = error
            }
        }
        
        // ④ Try NSMutableAttributedString if NSAttributedString failed
        if attributed == nil {
            do {
                attributed = try NSKeyedUnarchiver
                    .unarchivedObject(ofClass: NSMutableAttributedString.self, from: data)
            } catch {
                lastError = error
            }
        }
        
        // ---------- extract visible text ----------
        guard let attr = attributed else {
            print("❌ Failed to decode attributed string. Last error: \(lastError?.localizedDescription ?? "unknown")")
            
            // Fallback: Try to extract text directly from the hex data
            if let fallbackText = extractTextFromHex(data) {
                print("🔧 Extracted fallback text: '\(fallbackText)'")
                return fallbackText
            }
            
            return ""
        }
        
        var result = attr.string                      // A. plain / emoji text
        
        // DEBUG: Print what we actually decoded
        debugLog("🔍 Decoded attributed string: '\(result)'")
        debugLog("🔍 Length: \(result.count), chars: \(result.unicodeScalars.map { String($0.value, radix: 16) })")
        
        // Check for URLs if string appears empty or contains only whitespace/control chars
        let visibleText = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if visibleText.isEmpty {
            // B. fallback: first URL attribute
            attr.enumerateAttribute(.link,
                                    in: NSRange(location: 0, length: attr.length),
                                    options: []) { value, _, stop in
                if let url = value as? URL {
                    result = url.absoluteString
                    debugLog("🔗 Using URL fallback: \(result)")
                    stop.pointee = true
                }
            }
        }
        
        return result
    }
    
    /// Fallback method to extract text directly from hex when NSKeyedUnarchiver fails
    private func extractTextFromHex(_ data: Data) -> String? {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        
        // Look for common patterns in the hex that indicate text content
        // The pattern typically appears after "4e53537472696e67019484012b" followed by length byte(s)
        let pattern = "4e53537472696e67019484012b"
        
        guard let range = hex.range(of: pattern) else { return nil }
        
        let afterPattern = String(hex[range.upperBound...])
        
        // The next 2 characters are typically the length in hex
        guard afterPattern.count >= 2 else { return nil }
        
        let lengthHex = String(afterPattern.prefix(2))
        guard let length = Int(lengthHex, radix: 16), length > 0, length < 200 else { return nil }
        
        // Extract the text bytes
        let textStartIndex = afterPattern.index(afterPattern.startIndex, offsetBy: 2)
        let textHex = String(afterPattern[textStartIndex...])
        
        guard textHex.count >= length * 2 else { return nil }
        
        let textBytes = String(textHex.prefix(length * 2))
        
        // Convert hex pairs to bytes and then to string
        var bytes: [UInt8] = []
        var index = textBytes.startIndex
        
        while index < textBytes.endIndex {
            let nextIndex = textBytes.index(index, offsetBy: 2)
            guard nextIndex <= textBytes.endIndex else { break }
            
            let byteString = String(textBytes[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            }
            index = nextIndex
        }
        
        guard !bytes.isEmpty else { return nil }
        
        // Try to decode as UTF-8
        if let text = String(bytes: bytes, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        
        return nil
    }
}

// MARK: - DB Internals
extension MessagesManager {
    private var messagesDBPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages/chat.db").path
    }
    
    internal var db: Connection? {
        try? Connection(messagesDBPath, readonly: true)
    }
}

// MARK: - Types
extension MessagesManager {
    /// each row is a single message.
    public struct Message: Identifiable, Equatable, Hashable {
        public var id: Int64 { ROWID }
        var ROWID: Int64
        var text: String
        var is_from_me: Int
        var date: Date
        var is_read: Int
        var handle_id: Int64
        var cache_has_attachments: Int
        var attachment: MessageAttachment
    }
    
    struct MessageAttachment: Equatable, Hashable {
        let filename: String
        let mimeType: String
        let filePath: String
        // Add data if you want to load it directly in memory:
        let fileData: Data?
        
        init(filename: String = "",
             mimeType: String = "",
             filePath: String = "",
             fileData: Data? = nil) {
            self.filename = filename
            self.mimeType = mimeType
            self.filePath = filePath
            self.fileData = fileData
        }
    }
    
    /// This represents a phone number or Apple ID you’re chatting with
    public struct Handle: Hashable {
        /// handle_id in Message points to this
        var ROWID: Int64
        
        var id: String
        var service: String
        var lastTalkedTo: Date
        var display_name: String
        var image: NSImage
        var lastMessage: String
    }
}

// MARK: - MessagesManager

@MainActor
final class MessagesManager: ObservableObject {
    /// Messages are stored in ~/Library/Messages/chat.db
    /// We Need to write SQL queries to fetch messages from this database
    /// we will setup a watcher to watch for the most latest messages
    static let shared = MessagesManager()
    
    internal var settingsManager: SettingsModel = .shared
    
    @Published var allHandles: [Handle] = []
    /// Holds the current messages with the user the user wants to talk to
    /// this will get reset on back or anything else
    @Published var currentUserMessages: [Message] = []

    @Published var hasFullDiskAccess: Bool = false
    @Published var hasContactAccess: Bool = false
    
    internal var isFetchingHandles = false
    internal var isFetchingMessages = false
    
    func checkContactAccess() {
        DispatchQueue.main.async {
            self.hasContactAccess = self.hasContactPermission()
        }
        
        if !self.hasContactAccess {
            requestContactAccess()
        }
    }
    
    func requestContactAccess() {
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                self.hasContactAccess = granted
            }
            
            if !granted {
                print("❌ Contacts permission denied: \(error?.localizedDescription ?? "No error info")")
            }
        }
    }
    
    private func hasContactPermission() -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return status == .authorized
    }
    
    /// Checks to make sure we have full disk access
    func checkFullDiskAccess() {
        let messagesDB = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages/chat.db")
        
        /// Try To Read the chat.db file if we can that means
        /// we have full disk access
        do {
            _ = try Data(contentsOf: messagesDB)
            DispatchQueue.main.async {
                self.hasFullDiskAccess = true
            }
        } catch {
            print("❌ Cannot access chat.db: \(error)")
            DispatchQueue.main.async {
                self.hasFullDiskAccess = false
            }
        }
    }
}

// MARK: - Fetching Handles
