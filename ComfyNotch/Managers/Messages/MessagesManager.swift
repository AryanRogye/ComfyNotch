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
    
    private var db: Connection? {
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
    }
}

final class MessagesManager: ObservableObject {
    /// Messages are stored in ~/Library/Messages/chat.db
    /// We Need to write SQL queries to fetch messages from this database
    /// we will setup a watcher to watch for the most latest messages
    static let shared = MessagesManager()
    
    @Published var hasFullDiskAccess: Bool = false
    @Published var hasContactAccess: Bool = false
    
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

/// Fetching Logic For Users
extension MessagesManager {
    public func fetchAllHandles() async -> [Handle] {
        guard let db = db else {
            print("🚫 DB not available")
            return []
        }
        
        let handleTable = Table("handle")
        /// ROWS For it
        let rowID   = SQLite.Expression<Int64>("ROWID")
        let id      = SQLite.Expression<String>("id")
        let service = SQLite.Expression<String>("service")
        
        var results: [Handle] = []
        
        do {
            for row in try db.prepare(handleTable) {
                
                let contact = await getContactName(for: row[id]) ?? row[id]
                print("Contact: \(contact), ID: \(row[id])")
                let lastTalkedTo = getLastTalkedTo(for: row[rowID])
                
                let h = Handle(
                    ROWID: row[rowID],
                    id: row[id],
                    service: row[service],
                    lastTalkedTo: lastTalkedTo,
                    display_name: contact
                )
                results.append(h)
            }
        } catch {
            print("Error Fetching All Handles: \(error)")
        }
        
        return results
    }
    
    /// We need to query the message table to get the last talked to for the handle id
    func getLastTalkedTo(for handleID: Int64) -> Date {
        guard let db = db else {
            print("🚫 DB not available")
            return .distantPast
        }
        
        let messageTable    = SQLite.Table("message")
        let handle_id       = SQLite.Expression<Int64>("handle_id")
        let date            = SQLite.Expression<Int64>("date")
        
        do {
            if let row = try db.pluck(
                messageTable
                    .filter(handle_id == handleID)
                    .order(date.desc)
                    .limit(1)
            ) {
                /// Apple Holds Messages in nanoseconds since 2001
                let timestamp = row[date]
                let refDate = Date(timeIntervalSinceReferenceDate: 0) // 2001-01-01
                
                // If it's greater than a huge number, assume it's in nanoseconds
                let seconds: Double
                if timestamp > 1_000_000_000_000 {
                    seconds = Double(timestamp) / 1_000_000_000
                } else {
                    seconds = Double(timestamp)
                }
                
                return refDate.addingTimeInterval(seconds)
            }
        } catch {
            print("❌ Error fetching last message date for handle \(handleID): \(error)")
        }
        
        return .distantPast
    }
    
    func getContactName(for identifier: String) async -> String? {
        print("🧪 Looking up contact for handle.id: \(identifier)")
        
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]
        
        return await Task.detached(priority: .userInitiated) { () -> String? in
            let store = CNContactStore()
            
            do {
                let allContacts = try store.unifiedContacts(
                    matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()),
                    keysToFetch: keysToFetch
                )
                
                for contact in allContacts {
                    for email in contact.emailAddresses {
                        if email.value as String == identifier {
                            return "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
                
                for contact in allContacts {
                    for number in contact.phoneNumbers {
                        let contactNum = number.value.stringValue.filter(\.isNumber)
                        let handleNum = identifier.filter(\.isNumber)
                        
                        if contactNum.hasSuffix(handleNum) || handleNum.hasSuffix(contactNum) {
                            return "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
                
                return nil
            } catch {
                print("❌ Contact fetch error: \(error)")
                return nil
            }
        }.value
    }
}
