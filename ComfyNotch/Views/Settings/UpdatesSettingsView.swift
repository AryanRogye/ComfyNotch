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
        ScrollView {
            VStack(spacing: 24) {
                if let icons = Bundle.main.infoDictionary?["CFBundleIconFile"] as? String {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(12)
                }
                Text("Version: \(Bundle.main.versionNumber)")
                Text("Build Number: \(Bundle.main.buildNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Button(action: {
                settings.checkForUpdates()
            }) {
                Text("Check For Updates")
                    .font(.headline)
                    .padding()
                    .cornerRadius(8)
            }
        }
    }
}


#Preview {
    UpdatesSettingsView(settings: SettingsModel.shared)
}
