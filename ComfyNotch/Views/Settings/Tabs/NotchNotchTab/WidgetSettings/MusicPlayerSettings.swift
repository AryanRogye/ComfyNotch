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
                    Toggle("Show Music Provider",isOn: $settings.showMusicProvider)
                    .toggleStyle(.switch)
                    .onChange(of: settings.showMusicProvider) {
                        settings.saveSettings()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
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
                .padding(.horizontal)
                
                Text("⚠️ Warning – Media Remote is a third-party Swift Package feature. Performance may vary, and optimizations may be limited.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                if settings.musicController == .mediaRemote {
                    
                    Divider()
                        .padding(.vertical, 8)

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
                    .padding([.horizontal, .bottom])
                }
            }
        }
    }
}
