//
//  MessagesManager+Messages.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/28/25.
//

import Cocoa
import SQLite

extension MessagesManager {
    
    public func sendMessage(for handle: Handle?) {
        guard !isMessaging else { return }
        isMessaging = true
        defer { isMessaging = false }
        
        /// Make Sure we have a handle
        guard let handle = handle else { return }
        /// Make Sure we have a valid messagesText
        if messagesText.isEmpty { return }
        let safeMessage = messagesText.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Messages"
            set targetService to 1st service whose service type = iMessage
            set targetBuddy to buddy "\(handle.id)" of targetService
            send "\(safeMessage)" to targetBuddy
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("❌ AppleScript error: \(error)")
            } else {
                print("✅ Message sent to \(handle.id)")
            }
        }
        
        /// Clear the messagesText
        messagesText = ""
        /// Fetch the latest messages for this user
        fetchMessagesWithUser(for: handle.ROWID)
    }
    
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

                // Always try to decode attributedBody if we don't have meaningful text
                if finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let attributedText = formatAttributedBody(row[attributedBody])
                    if !attributedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        finalText = attributedText
                    }
                }

                // Debug: Show what we actually got
                if !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("✅ Final text: '\(finalText)'")
                } else if let data = row[attributedBody] {
                    print("!!!!!!!!!!FOUND Attributed Body!!!!!!!!!!")
                    print("🧬 Raw attributedBody:", data.map { String(format: "%02x", $0) }.joined())
                    // Try to decode it manually to see what's wrong
                    let debugText = formatAttributedBody(data)
                    print("🔍 Debug decode result: '\(debugText)' (length: \(debugText.count))")
                    print("🔍 Debug bytes: \(debugText.utf8.map { String($0) }.joined(separator: ","))")
                }
                
                let attachment = getAttachment(for: row[ROWID]) ?? MessageAttachment()
                
                let message = Message(
                    ROWID: row[ROWID],
                    text: finalText,
                    is_from_me: row[is_from_me],
                    date: formatDate(row[date]),
                    is_read: row[is_read],
                    handle_id: row[handle_id],
                    cache_has_attachments: row[cache_has_attachments],
                    attachment: attachment
                )
                messages.append(message)
            }
            /// Update the currentUserMessages
            self.currentUserMessages = messages
        } catch {
            print("Error Fetching Messages: \(error)")
        }
    }
    
    private func getAttachment(for rowID: Int64) -> MessageAttachment? {
        guard let db = db else {
            print("🚫 DB not available")
            return nil
        }
        
        let joinTable       = SQLite.Table("message_attachment_join")
        let message_id      = SQLite.Expression<Int64>("message_id")
        let attachment_id   = SQLite.Expression<Int64>("attachment_id")
        
        let attachmentTable = SQLite.Table("attachment")
        let ROWID           = SQLite.Expression<Int64>("ROWID")
        let filename        = SQLite.Expression<String?>("filename")
        let mime_type       = SQLite.Expression<String?>("mime_type")

        do {
            /// Loop Through the JoinRow And Match Wuth the attachRow
            for joinRow in try db.prepare(
                joinTable
                    .filter(message_id == rowID)
            ) {
                if let attachRow = try db.pluck(
                    attachmentTable
                        .filter(ROWID == joinRow[attachment_id])
                ) {
                    return MessageAttachment(
                        filename: attachRow[filename] ?? "Unknown",
                        mimeType: attachRow[mime_type] ?? "application/octet-stream"
                        /// TODO: Construct FilePath and FileData too Sleepy
                    )
                }
            }
        } catch {
            
        }
        
        return nil
    }
}
