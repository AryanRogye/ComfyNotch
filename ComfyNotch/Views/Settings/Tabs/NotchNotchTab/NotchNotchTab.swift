//
//  NotchNotchTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct NotchNotchTab: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    @State private var utilsDidChange: Bool = false
    @State private var utilssettingsvalues = UtilsSettingsValues()
    
    @State private var messageDidChange: Bool = false
    @State private var messageTrayValues = MessagesSettingsValues()
    
    @State private var fileDidChange: Bool = false
    @State private var fileTrayValues = FileTraySettingsValues()
    
    var body: some View {
        VStack {
            ComfyScrollView {
                currentWidgetsDisplay
                selectWidgetsDisplay
                
                fileSettingsDisplay
                messageSettingsDisplay
                utilsSettingsDisplay
            }
        }
    }
    
    private var currentWidgetsDisplay: some View {
        ComfySettingsContainer {
            CurrentWidgetsDisplayView()
        } header: {
            Text("Currently Selected Widgets")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
    }
    
    private var selectWidgetsDisplay: some View {
        ComfySettingsContainer {
            SelectWidgetsView()
        } header: {
            Text("Select Widgets")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
        }
    }
    
    // MARK: - Messages
    private var messageSettingsDisplay: some View {
        ComfySettingsContainer {
            MessageSettingsView(
                didChange: $messageDidChange,
                values: $messageTrayValues
            )
        } header: {
            Text("Message Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            Button(action: {
                settings.saveMessagesValues(values: messageTrayValues)
                messageDidChange = false
            }) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        messageDidChange
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.1)
                    }
                    .foregroundColor(
                        messageDidChange
                        ? Color.red
                        : Color.green
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!messageDidChange)
            
        }
    }
    
    
    // MARK: - Utils
    private var utilsSettingsDisplay: some View {
        ComfySettingsContainer {
            UtilsSettingsView(
                didChange: $utilsDidChange,
                values: $utilssettingsvalues
            )
        } header: {
            Text("Utils Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            Button(action: {
                settings.saveUtilsValues(values: utilssettingsvalues)
                utilsDidChange = false
            }) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        utilsDidChange
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.1)
                    }
                    .foregroundColor(
                        utilsDidChange
                        ? Color.red
                        : Color.green
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!utilsDidChange)
            
        }
    }
    
    // MARK: - Files
    private var fileSettingsDisplay: some View {
        ComfySettingsContainer {
            FileTraySettingsView(
                didChange: $fileDidChange,
                values: $fileTrayValues
            )
        } header: {
            Text("File Tray Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            Button(action: {
                settings.saveFileTrayValues(values: fileTrayValues)
                fileDidChange = false
            }) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        fileDidChange
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.1)
                    }
                    .foregroundColor(
                        fileDidChange
                        ? Color.red
                        : Color.green
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!fileDidChange)
        }
    }
}
