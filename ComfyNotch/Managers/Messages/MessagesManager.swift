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
    internal var messagesDBPath: String {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages/chat.db")
            .path
    }
    
    internal var db: Connection? {
        try? Connection(messagesDBPath, readonly: true)
    }
}


// MARK: - MessagesManager

@MainActor
final class MessagesManager: ObservableObject {
    /// Messages are stored in ~/Library/Messages/chat.db
    /// We Need to write SQL queries to fetch messages from this database
    /// we will setup a watcher to watch for the most latest messages
    static let shared = MessagesManager()
    
    internal let settingsManager    : SettingsModel         = .shared
    internal let panelState         : PanelAnimationState   = .shared
    
    @Published var allHandles: [Handle] = []
    /// Holds the current messages with the user the user wants to talk to
    /// this will get reset on back or anything else
    @Published var currentUserMessages: [Message] = []
    
    @Published var hasFullDiskAccess: Bool = false
    @Published var hasContactAccess: Bool = false
    @Published var messagesText: String = ""
    
    /// Internal States for the Message Manager
    ///     This is used to make sure that
    ///     multiple operations are not being
    ///     executed at the same time, them being
    ///     triggered will be invalidated by
    ///     these flags
    internal var isFetchingHandles  = false
    internal var isFetchingMessages = false
    internal var isMessaging        = false
    internal var isPlayingAudio     = false
    
    internal var timer: Timer?
    internal var lastKnownModificationDate: Date?
    internal var lastLocalSendTimestamp: Date?
    
    internal var lastTriggerTime: DispatchTime = .now()
    internal var pendingNotchOpen: DispatchWorkItem?
    internal var messageCloseWorkItem: DispatchWorkItem?
    
    internal var dontShowFirstMessage: Bool = true
    internal var dbHandle: OpaquePointer?
    
    internal var isPolling = false
    
    public func start() {
        if SettingsModel.shared.enableMessagesNotifications {
            Task {
                /// Open the SQLite database connection
                if sqlite3_open_v2(
                    messagesDBPath,
                    &self.dbHandle,
                    SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_SHAREDCACHE,
                    nil
                ) == SQLITE_OK {
                    print("✅ SQLite DB opened and cached")
                } else {
                    print("❌ Failed to open SQLite DB")
                    self.dbHandle = nil
                }
                
                /// Check At start so no weird UI bug
                self.checkFullDiskAccess()
                self.checkContactAccess()
                await self.fetchAllHandles()
                self.startPolling()
            }
        }
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
        self.isPolling = false
        
        if let handle = self.dbHandle {
            sqlite3_close(handle)
            print("✅ SQLite DB closed")
            self.dbHandle = nil
        }
        
        hashmap_free()
    }
    
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
