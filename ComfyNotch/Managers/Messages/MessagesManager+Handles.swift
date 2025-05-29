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
                
                let (contact, image) = await getContactName(for: row[id]) ?? (row[id], nil)
                let nsImage = image
                    .flatMap(NSImage.init(data:))
                    ?? NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil)
                    ?? NSImage(size: NSSize(width: 40, height: 40))
                
                let lastTalkedTo = getLastTalkedTo(for: row[rowID])
                let lastMessage = getLastMessageWithUser(for: row[rowID]) ?? ""

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
    
    func getLastMessageWithUser(for handleID: Int64) -> String? {
        guard let db = db else {
            print("🚫 DB not available")
            return nil
        }
        
        let messageTable = SQLite.Table("message")
        let handle_id    = SQLite.Expression<Int64>("handle_id")
        let text         = SQLite.Expression<String?>("text")
        let date         = SQLite.Expression<Int64>("date")
        
        
        let attributedBody = SQLite.Expression<Data?>("attributedBody")

        do {
            if let row = try db.pluck(
                messageTable
                    .filter(handle_id == handleID)
                    .order(date.desc)
                    .limit(1)
            ) {
                let rawText = row[text]
                var finalText = rawText ?? ""

                if finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let attributedText = formatAttributedBody(row[attributedBody])
                    if !attributedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        finalText = attributedText
                    }
                }

                return finalText
            }
        } catch {
            print("❌ Error fetching last message for handle \(handleID): \(error)")
        }
        
        return nil
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
                return self.formatDate(row[date])
            }
        } catch {
            print("❌ Error fetching last message date for handle \(handleID): \(error)")
        }
        
        return .distantPast
    }
    
    func getContactName(for identifier: String) async -> ContactResult? {
        await Task(priority: .background) {
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
                    if contact.emailAddresses.contains(where: { $0.value as String == identifier }) {
                        return ("\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces), contact.imageData)
                    }
                }
                
                for contact in allContacts {
                    for number in contact.phoneNumbers {
                        let contactNum = number.value.stringValue.filter(\.isNumber)
                        let handleNum = identifier.filter(\.isNumber)
                        if contactNum.hasSuffix(handleNum) || handleNum.hasSuffix(contactNum) {
                            return ("\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces), contact.imageData)
                        }
                    }
                }
            } catch {
                print("❌ Contact fetch error: \(error)")
            }
            
            return nil
        }.value
    }
}
