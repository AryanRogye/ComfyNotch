//
//  QuickAccessSettingsView+FileTray.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct QuickAccessSettingsView_FileTray: View {
    @ObservedObject var settings: SettingsModel = .shared
    @State var selectedFolder: URL?
    
    @State private var isShowingAllowedOnLocalhost: Bool = false
    
    var body: some View {
        VStack {
            titleView
            
            persistFileTray()
            Divider()
            saveToFolder()
            allowToOpenOnLocalhost
        }
        .onAppear {
            isShowingAllowedOnLocalhost = settings.fileTrayAllowOpenOnLocalhost
        }
    }
    
    private var allowToOpenOnLocalhost: some View {
        VStack {
            toggleableAllow
            
            Text("This allows you to drag in a file and get a QR code to scan with your phone. Note: This is not encrypted and anyone on the same network can access your files, there is a pin that you must enter to allow access to the file. But that is all.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            if isShowingAllowedOnLocalhost {
                portPicker
                localHostPin
            }
        }
    }
    
    private var localHostPin: some View {
        HStack {
            Text("Localhost PIN")
            Spacer()
            TextField("1111", text: $settings.localHostPin)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
                .onSubmit {
                    if isValidPin(settings.localHostPin) {
                        settings.saveSettings()
                    } else {
                        NSSound.beep()
                    }
                }
                .onChange(of: settings.localHostPin) {
                    settings.localHostPin = settings.localHostPin.trimmingCharacters(in: .whitespaces)
                }
        }
    }
    
    private func isValidPin(_ pin: String) -> Bool {
        pin.count == 4 && pin.allSatisfy(\.isNumber)
    }
    
    private var portPicker: some View {
        HStack {
            Text("Default Port")
            Spacer()
            TextField("0000", value: $settings.fileTrayPort, formatter: NumberFormatter.portFormatter)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
                .onSubmit {
                    settings.saveSettings()
                }
        }
    }
    
    private var toggleableAllow: some View {
        HStack {
            Text("Allow to open on localhost")
            Spacer()
            Toggle(isOn: $settings.fileTrayAllowOpenOnLocalhost) {
                Text("")
            }
            .toggleStyle(.switch)
            .onChange(of: settings.fileTrayAllowOpenOnLocalhost) { _, newValue in
                settings.saveSettings()
                withAnimation(.easeInOut(duration: 0.4)) {
                    isShowingAllowedOnLocalhost = newValue
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Title
    private var titleView: some View {
        HStack {
            Text("FileTray Settings")
                .font(.largeTitle)
            Spacer()
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
            Toggle(isOn: $settings.fileTrayPersistFiles) {
                Text("")
            }
            .toggleStyle(.switch)
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
