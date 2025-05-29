//
//  MessagesView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/27/25.
//

import SwiftUI

struct MessagesView: View {
    
    @StateObject var animationState = PanelAnimationState.shared
    @StateObject var messagesManager = MessagesManager.shared
    
    @State var didPressUser: Bool = false
    @State var clickedUser: MessagesManager.Handle?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !messagesManager.hasFullDiskAccess {
                handleNoDiskAccess
                    .padding(5)
            } else if !messagesManager.hasContactAccess {
                handleNoContactAccess
                    .padding(5)
            } else {
                /// Show Regular Content
                userMessagesHomePage
            }
        }
        .onAppear {
            messagesManager.checkFullDiskAccess()
            messagesManager.checkContactAccess()
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 2 : 0.1),
            value: animationState.isExpanded
        )
    }
    
    private var userMessagesHomePage: some View {
        HStack(spacing: 0) {
            userHandles
            /// Actual Users Messages if user pressed on a handle
            if didPressUser {
                userClickedMessagePage
            }
        }
    }
    
    private var userHandles: some View {
        ComfyScrollView {
            /// TODO: Add Favorites Section
            /// TODO: At Top Add Search Bar
            ForEach(messagesManager.allHandles.sorted(by: { $0.lastTalkedTo > $1.lastTalkedTo } ), id: \.self) { handle in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        didPressUser = true
                    }
                    clickedUser = handle
                    Task.detached {
                        await MainActor.run {
                            messagesManager.fetchMessagesWithUser(for: handle.ROWID)
                        }
                        /// Once Done Just Print for now
                        await messagesManager.currentUserMessages.forEach({message in
                            print("\(message.is_from_me) \(message.text)")
                        })
                    }
                }) {
                    HStack {
                        /// Image of Person
                        userImage(for: handle)
                        VStack {
                            HStack {
                                /// Name of Person
                                nameOfPerson(for: handle)
                                
                                Spacer()
                                /// Date Last Talked To
                                dateLastTalkedTo(for: handle)
                            }
                            /// Last Message To User
                            Text(handle.lastMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            fetchHandles()
        }

    }
    
    private var userClickedMessagePage: some View {
        VStack {
            userClickedMessageTopRow
                .padding(5)
            ComfyScrollView {
                userCLickedMessageMessages
            }
        }
    }
    
    private var userCLickedMessageMessages: some View {
        VStack {
            ForEach(messagesManager.currentUserMessages, id: \.self) { message in
                /// If Message From Me Show Right And Blue
                if message.is_from_me != 0 {
                    HStack {
                        Spacer()
                        Text(message.text)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                else {
                    HStack {
                        Text(message.text)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var userClickedMessageTopRow: some View {
        VStack {
            HStack {
                Text(clickedUser?.display_name ?? "Unkown Name")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                closeButton
            }
            Divider()
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.didPressUser = false
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
    
    private func userImage(for handle: MessagesManager.Handle) -> some View {
        VStack (alignment: .leading) {
            Image(nsImage: handle.image)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        }
    }
    
    private func nameOfPerson(for handle: MessagesManager.Handle) -> some View {
        VStack(alignment: .leading) {
            Text(handle.display_name)
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
    }
    
    private func dateLastTalkedTo(for handle: MessagesManager.Handle) -> some View {
        /// Date Last Talked To
        VStack(alignment: .trailing) {
            Text(formatDate(handle.lastTalkedTo))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var handleNoDiskAccess: some View {
        VStack {
            /// Prompt the user to enable Full Disk Access
            Text("ComfyNotch needs Full Disk Access to read iMessage data. Please enable it in System Settings → Privacy & Security → Full Disk Access.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            /// Provide a button to open System Settings
            Button(action: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
            }) {
                Text("Click Here to Open System Settings")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            Spacer()
        }
    }
    
    private var handleNoContactAccess: some View {
        VStack {
            /// Prompt the user to enable Contacts Access
            Text("ComfyNotch needs access to your Contacts to display names. Please enable it in System Settings → Privacy & Security → Contacts.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            /// Provide a button to open System Settings
            Button(action: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")!)
            }) {
                Text("Click Here to Open System Settings")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            Spacer()
        }
    }
    
    // MARK: - Fetch Messages
    
    private func fetchHandles() {
        Task {
            await messagesManager.fetchAllHandles()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        /// Apple Messages Formats Dates where if it was sent in the last week, it shows up
        /// with the day, or else it shows up with the date in the format mm/dd/yyyy <- yyyy is just last 2
        let cal = Calendar.current
        let now = Date()
        
        if cal.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        if let weekAgo = cal.date(byAdding: .day, value: -7, to: now),
           date >= weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // e.g., "Monday"
            return formatter.string(from: date)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}
