//
//  QuickAccessSettingsView+Messages.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct QuickAccessSettingsView_Messages: View {
    @ObservedObject var settings: SettingsModel = .shared
    
    var body: some View {
        VStack {
            titleView
            ComfySection(title: "Messages", isSub: true) {
                messagesSettings
            }
        }
    }
    
    // MARK: - Title
    private var titleView: some View {
        HStack {
            Text("Messages Settings")
                .font(.largeTitle)
            Spacer()
        }
    }
    
    private var messagesSettings: some View {
        HStack {
            /// One Side Messages Controls
            VStack {
                /// Toggle for Messages Notifications
                Toggle(isOn: $settings.enableMessagesNotifications) {
                    Label("Enable Messages Notifications", systemImage: "message.fill")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .onChange(of: settings.enableMessagesNotifications) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if newValue {
                            /// Logic When Turned On
                            Task {
                                MessagesManager.shared.checkFullDiskAccess()
                                MessagesManager.shared.checkContactAccess()
                                await MessagesManager.shared.fetchAllHandles()
                                MessagesManager.shared.startPolling()
                            }
                        } else {
                            /// Logic When Turned Off
                            MessagesManager.shared.stopPolling()
                        }
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                /// Suggestion
                Button(action: {
                    /// Open Notifications Settings
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications?Messages")!)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.slash.fill")
                        Text("We recommend disabling notifications for the Messages app.")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                if settings.enableMessagesNotifications {
                    Group {
                        /// TODO:  show that this is for getting the "last amount" of users
                        ComfyLabeledStepper(
                            "Most Recent Message Limit",
                            value: $settings.messagesHandleLimit,
                            in: 10...100,
                            step: 1
                        )
                        
                        /// Actual last message content
                        ComfyLabeledStepper(
                            "Control Message Limit",
                            value: $settings.messagesMessageLimit,
                            in: 10...100,
                            step: 1
                        )
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
            }
            
            Spacer()
            
            /// TODO: Add Video demo here once the feature is made lol
        }
    }
}
