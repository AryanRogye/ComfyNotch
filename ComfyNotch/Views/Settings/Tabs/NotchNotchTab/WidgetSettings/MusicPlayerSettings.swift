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
            showMusicProvider
                .padding(.horizontal)
                .padding(.top, 8)

            Divider()
                .padding(.vertical, 8)


           musicControllerPicker 

            if settings.musicController == .mediaRemote {

                Divider()
                    .padding(.vertical, 8)
                musicProviderPicker
            }
        }
    }

    // MARK: - Music Provider
    private var showMusicProvider: some View {
        HStack {
            Text("Show Music Provider")
                .font(.body)
            Spacer()
            Toggle("",isOn: $settings.showMusicProvider)
                .labelsHidden()
                .toggleStyle(.switch)
                .onChange(of: settings.showMusicProvider) {
                    settings.saveSettings()
                }
        }
    }

    // MARK: - Music Controller Picker
    private var musicControllerPicker: some View {
        VStack {
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
            /// Picker For Selecting the Music Controller
            /// Warning message about Media Remote
            Text("⚠️ Warning – Media Remote is a third-party Swift Package feature. Performance may vary, and optimizations may be limited.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Music Provider Picker
    private var musicProviderPicker: some View {
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
