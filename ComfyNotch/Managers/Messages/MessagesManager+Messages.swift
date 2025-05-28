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
        
        let messageTable = SQLite.Table("message")
        let ROWID = SQLite.Expression<Int64>("ROWID")
        let handle_id    = SQLite.Expression<Int64>("handle_id")
        let text         = SQLite.Expression<String?>("text")
        let is_from_me   = SQLite.Expression<Int>("is_from_me")
        let date         = SQLite.Expression<Int64>("date")
        let is_read      = SQLite.Expression<Int>("is_read")
        let cache_has_attachments = SQLite.Expression<Int>("cache_has_attachments")
        
        var messages : [Message] = []
        
        do {
            /// Loop Through messages with the rowID or the user
            for row in try db.prepare(
                messageTable
                    .filter(handle_id == rowID)
                    .order(date.desc)
                    .limit(20)
            ) {
                /// Create a Message Object
                let message = Message(
                    ROWID: row[ROWID],
                    text: row[text] ?? "",
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
