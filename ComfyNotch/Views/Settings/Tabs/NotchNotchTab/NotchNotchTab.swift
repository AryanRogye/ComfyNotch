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
    
    @State private var topNotchValues = TopNotchCustomizationSettingsValues()
    @State private var topNotchDidChange: Bool = false
    
    @State private var detailsClicked: Bool = false
    
    var body: some View {
        VStack {
            TabView {
                ComfyScrollView {
                    topNotchCustomizationSettings
                    fileSettingsDisplay
                    messageSettingsDisplay
                    utilsSettingsDisplay
                }
                .tabItem {
                    Label("Notch Screen Options", systemImage: "gearshape")
                }
                
                ComfyScrollView {
                    currentWidgetsDisplay
                    selectWidgetsDisplay
                }
                .tabItem {
                    Label("Widgets", systemImage: "square.grid.2x2")
                }
                
            }
        }
        .sheet(isPresented: $detailsClicked) {
            DetailsView(detailsClicked: $detailsClicked)
        }
    }
    
    private var topNotchCustomizationSettings: some View {
        ComfySettingsContainer {
            TopNotchCustomization(
                didChange: $topNotchDidChange,
                values: $topNotchValues
            )
        } header: {
            Text("Top View Customization")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            //            ComfyButton(title: "Save")
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
            
            Button(action: {
                detailsClicked = true
            }) {
                Text("Details...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .controlSize(.small)
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
            
            ComfyButton(title: "Save", $messageDidChange) {
                settings.saveMessagesValues(values: messageTrayValues)
                messageDidChange = false
            }
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
            
            ComfyButton(title: "Save", $utilsDidChange) {
                settings.saveUtilsValues(values: utilssettingsvalues)
                utilsDidChange = false
            }
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
            
            ComfyButton(title: "Save", $fileDidChange) {
                settings.saveFileTrayValues(values: fileTrayValues)
                fileDidChange = false
            }
        }
    }
}
