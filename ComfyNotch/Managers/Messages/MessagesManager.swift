//
//  MessagesManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/27/25.
//

import SwiftUI
import SQLite
import Contacts

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
    public struct Message: Identifiable, Equatable {
        public var id: Int64 { ROWID }
        var ROWID: Int64
        var text: String
        var is_from_me: Int
        var date: Date
        var is_read: Int
        var handle_id: String
        var cache_has_attachments: Int
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
    
    @Published var allHandles: [Handle] = []

    @Published var hasFullDiskAccess: Bool = false
    @Published var hasContactAccess: Bool = false
    
    internal var isFetchingHandles = false
    
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
