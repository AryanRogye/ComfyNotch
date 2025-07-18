//
//  NotchNotchTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct NotchNotchTab: View {
    
    @State private var utilsDidChange: Bool = false
    @State private var messageDidChange: Bool = false
    
    @State private var fileDidChange: Bool = false
    @State private var fileTrayValues = FileTraySettingsValues()
    
    var body: some View {
        VStack {
            ComfyScrollView {
                currentWidgetsDisplay
                selectWidgetsDisplay
                
                messageSettingsDisplay
                utilsSettingsDisplay
                fileSettingsDisplay
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
                didChange: $messageDidChange
            )
        } header: {
            Text("Message Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
    }
    
    
    // MARK: - Utils
    private var utilsSettingsDisplay: some View {
        ComfySettingsContainer {
            UtilsSettingsView(
                didChange: $utilsDidChange
            )
        } header: {
            Text("Utils Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
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
        }
    }
    
}
