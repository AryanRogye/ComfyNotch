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
    
    @State var userHandles: [MessagesManager.Handle] = []
    
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
        VStack(spacing: 0) {
            ComfyScrollView {
                ForEach(userHandles.sorted(by: { $0.lastTalkedTo > $1.lastTalkedTo } ), id: \.self) { handle in
                    HStack {
                        Text(handle.id)
                        Text(handle.display_name)
                        Text(dateFormatter.string(from: handle.lastTalkedTo))
                    }
                }
            }
            .onAppear {
                fetchHandles()
            }
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
            self.userHandles = await messagesManager.fetchAllHandles()
        }
    }
}
