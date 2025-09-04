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
        
        /// Make Sure we have a handle and message is valid is not empty
        guard let handle = handle, !messagesText.isEmpty else { return }
        let safeMessage = messagesText.replacingOccurrences(of: "\"", with: "\\\"")
        self.lastLocalSendTimestamp = Date()
        self.messagesText = ""
        
        let script = """
        tell application "Messages"
            set targetService to 1st service whose service type = iMessage
            set targetBuddy to buddy "\(handle.id)" of targetService
            send "\(safeMessage)" to targetBuddy
        end tell
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.executeAppleScript(script, for: handle)
        }
    }
    
    nonisolated private func executeAppleScript(_ script: String, for handle: Handle) {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
        
        let errorDescription = error?.description // ✅ safe String copy
        
        DispatchQueue.main.async {
            if let errorDescription = errorDescription {
                print("❌ AppleScript error: \(errorDescription)")
            } else {
                print("✅ Message sent to \(handle.id)")
            }
            
            self.lastLocalSendTimestamp = Date()
            self.fetchMessagesWithUser(for: handle.ROWID)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.fetchMessagesWithUser(for: handle.ROWID)
            }
            self.isMessaging = false
        }
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
                
                /// TODO: Construct the MessageAttachment
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
            print("Couldnt Get The Attachment")
        }
        
        return nil
    }
}
