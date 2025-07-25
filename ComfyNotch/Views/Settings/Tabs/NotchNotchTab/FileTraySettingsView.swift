//
//  FileTraySettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct FileTraySettingsValues: Equatable {
    var fileTrayDefaultFolder : URL? = nil
    var fileTrayAllowOpenOnLocalhost: Bool = false
    var localHostPin: String = "1111"
    var fileTrayPort: Int = 8080
}

public struct FileTraySettingsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @Binding var v: FileTraySettingsValues
    
    @State private var tempPin: String = "1111"
    
    @State private var hasAppeared = false
    @State private var originalState: FileTraySettingsValues = .init()
    
    init(didChange: Binding<Bool>, values: Binding<FileTraySettingsValues>) {
        self._didChange = didChange
        self._v = values
    }
    
    // MARK: - Body
    public var body: some View {
        VStack {
            saveToFolder()
            
            Divider().padding(.vertical, 8)
            
            allowToOpenOnLocalhost
        }
        .onAppear {
            v.fileTrayAllowOpenOnLocalhost = settings.fileTrayAllowOpenOnLocalhost
            v.fileTrayDefaultFolder = settings.fileTrayDefaultFolder
            v.localHostPin = settings.localHostPin
            tempPin = v.localHostPin
            
            originalState = FileTraySettingsValues(
                fileTrayDefaultFolder : settings.fileTrayDefaultFolder,
                fileTrayAllowOpenOnLocalhost: settings.fileTrayAllowOpenOnLocalhost,
                localHostPin: settings.localHostPin,
                fileTrayPort: settings.fileTrayPort
            )
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
        .onChange(of: v) { _, newValue in
            guard hasAppeared else { return }
            didChange = newValue != originalState
        }
    }
    
    // MARK: - Allow to open on localhost
    private var allowToOpenOnLocalhost: some View {
        VStack {
            toggleableAllow
                .padding(.horizontal)
            
            Text("""
                This allows you to drag in a file and get a QR code to scan with your phone. 
                Note: This is not encrypted and anyone on the same network can access your files, 
                there is a pin that you must enter to allow access to the file. But that is all.
                """)
            .frame(height: 50)
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .textSelection(.enabled) // optional
            .layoutPriority(1)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if v.fileTrayAllowOpenOnLocalhost {
                
                Divider().padding(.bottom, 8)
                
                VStack() {
                    portPicker
                        .padding(.vertical, 4)
                    Divider().padding(.vertical, 8)
                    localHostPin
                        .padding(.bottom)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    
    // MARK: - Pin Picker
    private var localHostPin: some View {
        HStack {
            Text("Localhost Pin")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            TextField("1111", text: $tempPin)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
                .onSubmit {
                    if isValidPin(tempPin) {
                        v.localHostPin = tempPin
                    } else {
                        NSSound.beep()
                    }
                }
        }
        .padding(.horizontal)
    }
    
    private func isValidPin(_ pin: String) -> Bool {
        pin.count == 4 && pin.allSatisfy(\.isNumber)
    }
    
    
    // MARK: - Port Picker
    private var portPicker: some View {
        HStack {
            Text("Default Port")
            Spacer()
            TextField("0000", value: $v.fileTrayPort, formatter: NumberFormatter.portFormatter)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Toggle Allow to Open on Localhost
    private var toggleableAllow: some View {
        HStack {
            Text("Allow to open on localhost")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            Toggle(isOn: $v.fileTrayAllowOpenOnLocalhost) {
                Text("")
            }
            .toggleStyle(.switch)
            .onChange(of: v.fileTrayAllowOpenOnLocalhost) { _, newValue in
                withAnimation(.easeInOut(duration: 0.4)) {
                    v.fileTrayAllowOpenOnLocalhost = newValue
                }
            }
        }
    }
    
    // MARK: - Pick Default Folder
    @ViewBuilder
    func saveToFolder() -> some View {
        HStack {
            Text("Filetray Default Folder:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "folder")
                Text(v.fileTrayDefaultFolder?.lastPathComponent ?? "Choose…")
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
            )
            .onTapGesture {
                pickFolder()
            }
        }
        .padding([.horizontal, .top])
    }
    
    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                v.fileTrayDefaultFolder = url
                settings.fileTrayDefaultFolder = url
                /// Save Settings After, Think I'll add a check to see if its the same or not
                settings.saveSettings()
            }
        }
    }
    
}
