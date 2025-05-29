//
//  MessagesManager+Types.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/29/25.
//

import Cocoa

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
