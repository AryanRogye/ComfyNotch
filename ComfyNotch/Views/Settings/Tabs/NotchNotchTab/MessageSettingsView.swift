//
//  MessageSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct MessagesSettingsValues: Equatable {
    var enableMessagesNotifications: Bool = false
    var messagesHandleLimit: Int = 20
    var messagesMessageLimit: Int = 20
}

public struct MessageSettingsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @Binding var v: MessagesSettingsValues
    
    @State private var hasAppeared = false
    @State private var originalState: MessagesSettingsValues = .init()
    
    init(didChange: Binding<Bool>, values: Binding<MessagesSettingsValues>) {
        self._didChange = didChange
        self._v = values
    }
    
    private var currentState: MessagesSettingsValues {
        return v
    }
    
    private var savedState: MessagesSettingsValues {
        return MessagesSettingsValues(
            enableMessagesNotifications: settings.enableMessagesNotifications,
            messagesHandleLimit:  settings.messagesHandleLimit,
            messagesMessageLimit:  settings.messagesMessageLimit
        )
    }
    
    public var body: some View {
        HStack {
            messagesSettings
        }
        .onAppear {
            v.enableMessagesNotifications = settings.enableMessagesNotifications
            v.messagesHandleLimit = settings.messagesHandleLimit
            v.messagesMessageLimit = settings.messagesMessageLimit
            
            originalState = MessagesSettingsValues(
                enableMessagesNotifications: settings.enableMessagesNotifications,
                messagesHandleLimit: settings.messagesHandleLimit,
                messagesMessageLimit: settings.messagesMessageLimit
            )
            
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
        .onChange(of: v) { _, newValue in
            guard hasAppeared else { return }
            didChange = newValue != savedState
        }
    }
    
    private var messagesSettings: some View {
        /// One Side Messages Controls
        VStack {
            /// Toggle for Messages Notifications
            Toggle(isOn: $v.enableMessagesNotifications) {
                Label("Enable Messages Notch View", systemImage: "message.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.vertical, 8)
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
            .padding(.top, 4)
            
            Divider().padding(.vertical, 8)

            if v.enableMessagesNotifications {
                VStack {
                    /// TODO:  show that this is for getting the "last amount" of users
                    ComfySlider(
                        value: $v.messagesHandleLimit,
                        in: 10...100,
                        step: 1,
                        label: "Most Recent User Limit"
                    )
                    .padding(.horizontal)

                    Divider().padding(.vertical, 8)
                    
                    /// Actual last message content
                    ComfySlider(
                        value: $v.messagesMessageLimit,
                        in: 10...100,
                        step: 1,
                        label: "Control Message Limit"
                    )
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
