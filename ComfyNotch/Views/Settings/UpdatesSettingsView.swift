//
//  UpdatesSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/24/25.
//

import SwiftUI

struct UpdatesSettingsView: View {
    @ObservedObject var settings: SettingsModel

    var body: some View {
        Form {
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)

                Text("Version \(Bundle.main.versionNumber)")
                    .font(.body)
                
                Text("Build \(Bundle.main.buildNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("View Release Notes") {
                    if let url = URL(string: "https://github.com/AryanRogye/ComfyNotch/releases/latest") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.footnote)
                
                Divider()
                
                Button("Check for Updates") {
                    settings.checkForUpdates()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut("u", modifiers: [.command])
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}


#Preview {
    UpdatesSettingsView(settings: SettingsModel.shared)
}
