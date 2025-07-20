//
//  MusicPlayerSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct MusicPlayerSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $settings.showMusicProvider) {
                        Text("Show Music Provider")
                    }
                    .toggleStyle(.switch)
                    .onChange(of: settings.showMusicProvider) {
                        settings.saveSettings()
                    }
                }
                
                Picker("Music Controller", selection: $settings.musicController) {
                    ForEach(MusicController.allCases, id: \.self) { controller in
                        Text(controller.displayName)
                            .tag(controller)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settings.musicController) {
                    settings.saveSettings()
                }
                Text("⚠️ Warning – Media Remote is a third-party Swift Package feature. Performance may vary, and optimizations may be limited.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                if settings.musicController == .mediaRemote {
                    Picker("Music Provider", selection: $settings.overridenMusicProvider) {
                        ForEach(MusicProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settings.overridenMusicProvider) {
                        settings.saveSettings()
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
