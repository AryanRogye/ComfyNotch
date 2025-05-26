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
        ComfyScrollView {
            Text("File Tray Settings")
            
            persistFileTray()
            Divider()
            saveToFolder()
            
            Spacer()
        }
        .onAppear {
            selectedFolder = settings.fileTrayDefaultFolder
        }
    }
    
    @ViewBuilder
    func saveToFolder() -> some View {
        if settings.fileTrayPersistFiles {
            HStack {
                Text("Filetray Default Folder:")
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text(selectedFolder?.lastPathComponent ?? "Choose…")
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
    }
    
    @ViewBuilder
    func persistFileTray() -> some View {
        HStack {
            Text("Persist Files")
            Spacer()
            MacSwitch(isOn: $settings.fileTrayPersistFiles)
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


struct MacSwitch: NSViewRepresentable {
    @Binding var isOn: Bool

    func makeNSView(context: Context) -> NSSwitch {
        let toggle = NSSwitch()
        toggle.target = context.coordinator
        toggle.action = #selector(Coordinator.changed(_:))
        return toggle
    }

    func updateNSView(_ nsView: NSSwitch, context: Context) {
        nsView.state = isOn ? .on : .off
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isOn: $isOn)
    }

    class Coordinator: NSObject {
        var isOn: Binding<Bool>

        init(isOn: Binding<Bool>) {
            self.isOn = isOn
        }

        @objc func changed(_ sender: NSSwitch) {
            isOn.wrappedValue = (sender.state == .on)
        }
    }
}
