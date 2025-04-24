//
//  FileTraySettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/24/25.
//

import SwiftUI
import AppKit

struct FileTraySettingsView: View {
    @ObservedObject var settings: SettingsModel
    @State var selectedFolder: URL?

    var body: some View {
        VStack {
            Text("File Tray Settings")
            
            HStack {
                Text("Select Default Folder To Save Files To")
                
                VStack {
                    Button("Pick a Folder") {
                        pickFolder()
                    }
                    Text(selectedFolder?.path ?? "Pick A Folder")
                }
            }
            Spacer()
        }
        .onAppear {
            selectedFolder = settings.fileTrayDefaultFolder
        }
    }
    
    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"

        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedFolder = url
                settings.fileTrayDefaultFolder = url
                /// Save Settings After, Think I'll add a check to see if its the same or not
                settings.saveSettings()
            }
        }
    }
}
