//
//  MessagesManager+Messages.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/28/25.
//

import Cocoa
import SQLite

extension MessagesManager {
    public func fetchMessagesWithUser(for rowID: Int64) {
        
        if isFetchingMessages { return }
        isFetchingMessages = true
        defer { isFetchingMessages = false }
        
        guard let db = db else {
            print("🚫 DB not available")
            return
        }
        
        /// Clear Current Messages Before Anything
        self.clearCurrentUserMessages()
        
        let messageTable = SQLite.Table("message")
        let ROWID = SQLite.Expression<Int64>("ROWID")
        let handle_id    = SQLite.Expression<Int64>("handle_id")
        let text         = SQLite.Expression<String?>("text")
        let is_from_me   = SQLite.Expression<Int>("is_from_me")
        let date         = SQLite.Expression<Int64>("date")
        let is_read      = SQLite.Expression<Int>("is_read")
        let cache_has_attachments = SQLite.Expression<Int>("cache_has_attachments")
        let attributedBody = SQLite.Expression<Data?>("attributedBody")
        
        var messages : [Message] = []
        
        do {
            /// Loop Through messages with the rowID or the user
            for row in try db.prepare(
                messageTable
                    .filter(handle_id == rowID)
                    .order(date.desc)
                    .limit(settingsManager.messagesMessageLimit)
            ) {
                let rawText = row[text]
                var finalText = rawText ?? ""

                if finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let data = row[attributedBody],
                       let attrStr = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
                        finalText = attrStr.string
                    }
                }            /// Create a Message Object
//                if let data = row[attributedBody], finalText.isEmpty {
//                    print("!!!!!!!!!!FOUND Attributed Body!!!!!!!!!!")
//                    print("🧬 Raw attributedBody:", data.map { String(format: "%02x", $0) }.joined())
//                }
                let message = Message(
                    ROWID: row[ROWID],
                    text: finalText,
                    is_from_me: row[is_from_me],
                    date: formatDate(row[date]),
                    is_read: row[is_read],
                    handle_id: row[handle_id],
                    cache_has_attachments: row[cache_has_attachments]
                )
                messages.append(message)
            }
            /// Update the currentUserMessages
            self.currentUserMessages = messages
        } catch {
            print("Error Fetching Messages: \(error)")
        }
    }
}
