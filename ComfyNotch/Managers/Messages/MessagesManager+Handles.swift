//
//  MessagesManager+Handles.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/28/25.
//

import Contacts
import Cocoa
import SQLite

extension MessagesManager {
    typealias ContactResult = (name: String, imageData: Data?)
    
    public func fetchAllHandles() async {
        
        if isFetchingHandles { return }
        isFetchingHandles  = true
        defer { isFetchingHandles = false }
        
        guard let db = db else {
            print("🚫 DB not available")
            return
        }
        
        let handleTable = Table("handle")
        /// ROWS For it
        let rowID   = SQLite.Expression<Int64>("ROWID")
        let id      = SQLite.Expression<String>("id")
        let service = SQLite.Expression<String>("service")
        
        var results: [Handle] = []
        
        do {
            for row in try db.prepare(
                handleTable
                    .limit(settingsManager.messagesHandleLimit)
            ) {
                
                let (contact, imageData) = await getContactName(for: row[id]) ?? (row[id], nil as Data?)
                
                // Process image data
                let processedImageData = imageData
                
                // Create NSImage on main actor (where it's safe to do UI work)
                let nsImage: NSImage = {
                    if let data = processedImageData, let contactImage = NSImage(data: data) {
                        return contactImage
                    }
                    
                    return NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil)
                    ?? {
                        let fallbackImage = NSImage(size: NSSize(width: 40, height: 40))
                        fallbackImage.lockFocus()
                        NSColor.systemGray.setFill()
                        NSRect(origin: .zero, size: NSSize(width: 40, height: 40)).fill()
                        fallbackImage.unlockFocus()
                        return fallbackImage
                    }()
                }()
                
                let lastTalkedTo = getLastTalkedTo(for: row[rowID])
                let lastMessage = getLastMessageWithUser(for: row[rowID])
                
                let h = Handle(
                    ROWID: row[rowID],
                    id: row[id],
                    service: row[service],
                    lastTalkedTo: lastTalkedTo,
                    display_name: contact,
                    image: nsImage,
                    lastMessage: lastMessage
                )
                results.append(h)
            }
        } catch {
            print("Error Fetching All Handles: \(error)")
        }
        self.allHandles = results
    }
    
    public func getLatestHandle() -> Handle? {
        /// self.allHandles has the handles we need, we just wanna send the one with the most
        /// recent date
        return self.allHandles.max(by: { $0.lastTalkedTo < $1.lastTalkedTo }) ?? nil
    }
    
    func getLastMessageWithUser(for handleID: Int64) -> String {
        guard let dbHandle = self.dbHandle else {
            print("❌ DB not available")
            return ""
        }
        
        guard let rawCString = get_last_message_text(dbHandle, handleID) else {
            return ""
        }
        
        let raw = String(cString: rawCString)
        
        if raw.hasPrefix("__BASE64__:") {
            let base64 = String(raw.dropFirst("__BASE64__:".count))
            if let data = Data(base64Encoded: base64) {
                return formatAttributedBody(data)
            } else {
                print("❌ Failed to decode base64 fallback")
                return ""
            }
        } else {
            return raw
        }
    }
    
    /// We need to query the message table to get the last talked to for the handle id
    func getLastTalkedTo(for handleID: Int64) -> Date {
        guard let dbHandle = self.dbHandle else {
            print("❌ DB not available")
            return .distantPast
        }
        
        let timestamp = get_last_talked_to(dbHandle, handleID)
        return formatDate(timestamp)
    }
    
    // MARK: - Contact Caching Properties
    private nonisolated(unsafe) static var contactCache: [String: ContactResult] = [:]
    private nonisolated(unsafe) static var phoneToContactMap: [String: String] = [:]
    private nonisolated(unsafe) static var emailToContactMap: [String: String] = [:]
    private nonisolated(unsafe) static var isContactCacheLoaded = false
    private static let contactCacheQueue = DispatchQueue(label: "contact.cache", qos: .utility)
    
    
    private func loadContactCacheIfNeeded() async {
        guard !Self.isContactCacheLoaded else { return }
        
        await withCheckedContinuation { continuation in
            Self.contactCacheQueue.async {
                guard !Self.isContactCacheLoaded else {
                    continuation.resume()
                    return
                }
                
                let keysToFetch: [CNKeyDescriptor] = [
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactFamilyNameKey as CNKeyDescriptor,
                    CNContactPhoneNumbersKey as CNKeyDescriptor,
                    CNContactEmailAddressesKey as CNKeyDescriptor,
                    CNContactImageDataKey as CNKeyDescriptor
                ]
                
                let store = CNContactStore()
                
                do {
                    let allContacts = try store.unifiedContacts(
                        matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()),
                        keysToFetch: keysToFetch
                    )
                    
                    for contact in allContacts {
                        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                        let contactData: ContactResult = (name: fullName, imageData: contact.imageData)
                        
                        // Cache by contact identifier
                        Self.contactCache[contact.identifier] = contactData
                        
                        // Build email mapping
                        for email in contact.emailAddresses {
                            let emailStr = email.value as String
                            Self.emailToContactMap[emailStr] = contact.identifier
                        }
                        
                        // Build phone mapping with multiple variations
                        for phoneNumber in contact.phoneNumbers {
                            let cleanNumber = phoneNumber.value.stringValue.filter(\.isNumber)
                            Self.phoneToContactMap[cleanNumber] = contact.identifier
                            
                            // Map last 10 digits for US numbers
                            if cleanNumber.count >= 10 {
                                let last10 = String(cleanNumber.suffix(10))
                                Self.phoneToContactMap[last10] = contact.identifier
                            }
                            
                            // Map last 7 digits for local matching
                            if cleanNumber.count >= 7 {
                                let last7 = String(cleanNumber.suffix(7))
                                Self.phoneToContactMap[last7] = contact.identifier
                            }
                        }
                    }
                    
                    Self.isContactCacheLoaded = true
                    debugLog("✅ Loaded \(allContacts.count) contacts into cache")
                    
                } catch {
                    print("❌ Contact cache load error: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Your existing function, now optimized
    func getContactName(for identifier: String) async -> ContactResult? {
        // Load cache on first use
        await loadContactCacheIfNeeded()
        
        // Fast cache lookup
        return await withCheckedContinuation { continuation in
            Self.contactCacheQueue.async {
                // Direct email lookup
                if let contactId = Self.emailToContactMap[identifier],
                   let cached = Self.contactCache[contactId] {
                    continuation.resume(returning: cached)
                    return
                }
                
                // Phone number lookup
                let cleanIdentifier = identifier.filter(\.isNumber)
                
                // Try exact match
                if let contactId = Self.phoneToContactMap[cleanIdentifier],
                   let cached = Self.contactCache[contactId] {
                    continuation.resume(returning: cached)
                    return
                }
                
                // Try suffix matching (still fast with hash map)
                for (cachedNumber, contactId) in Self.phoneToContactMap {
                    if cachedNumber.hasSuffix(cleanIdentifier) || cleanIdentifier.hasSuffix(cachedNumber) {
                        if let cached = Self.contactCache[contactId] {
                            continuation.resume(returning: cached)
                            return
                        }
                    }
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
}
