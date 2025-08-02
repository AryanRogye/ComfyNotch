//
//  MusicPlayerSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct MusicPlayerSettingsValues {
    var showMusicProvider: Bool = false
    var musicController: MusicController = .spotify_music
    var overridenMusicProvider: MusicProvider = .spotify
    var musicPlayerStyle : MusicPlayerWidgetStyle = .comfy
}

struct MusicPlayerSettings: View {
    
    @EnvironmentObject var settings : SettingsModel
    @Binding var didChange : Bool
    @Binding var values : MusicPlayerSettingsValues
    
    var body: some View {
        VStack {
            
            pickMusicPlayerStyles
            
            showMusicProvider
                .padding(.horizontal)
                .padding(.top, 8)

            Divider()
                .padding(.vertical, 8)

           musicControllerPicker
                .padding(.horizontal)
                .padding(.vertical, 4)
                .padding(.bottom, values.musicController == .spotify_music ? 8 : 0)

            if values.musicController == .mediaRemote {
                Divider()
                    .padding(.vertical, 8)
                musicProviderPicker
            }
        }
        .onAppear {
            values.showMusicProvider = settings.showMusicProvider
            values.musicController = settings.musicController
            values.overridenMusicProvider = settings.overridenMusicProvider
        }
        .onChange(of: values.showMusicProvider) { didValuesChange() }
        .onChange(of: values.musicController) { didValuesChange() }
        .onChange(of: values.overridenMusicProvider) { didValuesChange() }
    }
    
    private var pickMusicPlayerStyles: some View {
        HStack {
            ComfyPickerElement(
                isSelected: settings.musicPlayerStyle == .comfy,
                label: "Comfy"
            ) {
                settings.musicPlayerStyle = .comfy
            } content: {
                
            }
            
            ComfyPickerElement(
                isSelected: settings.musicPlayerStyle == .native,
                label: "Native"
            ) {
                settings.musicPlayerStyle = .native
            } content: {
                
            }
        }
    }
    
    private func didValuesChange() {
        let sM = values.showMusicProvider != settings.showMusicProvider
        let mc = values.musicController != settings.musicController
        let oMP = values.overridenMusicProvider != settings.overridenMusicProvider
        
        if sM || mc || oMP {
            didChange = true
        }
    }

    // MARK: - Music Provider
    private var showMusicProvider: some View {
        HStack {
            Text("Show Music Provider")
                .font(.body)
            Spacer()
            Toggle("",isOn: $values.showMusicProvider)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    // MARK: - Music Controller Picker
    private var musicControllerPicker: some View {
        VStack {
            Picker("Music Controller", selection: $values.musicController) {
                ForEach(MusicController.allCases, id: \.self) { controller in
                    Text(controller.displayName)
                        .tag(controller)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            /// Picker For Selecting the Music Controller
            /// Warning message about Media Remote
            Text("⚠️ Warning – Media Remote is a third-party Swift Package feature. Performance may vary, and optimizations may be limited.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Music Provider Picker
    private var musicProviderPicker: some View {
        Picker("Music Provider", selection: $values.overridenMusicProvider) {
            ForEach(MusicProvider.allCases, id: \.self) { provider in
                Text(provider.displayName)
                    .tag(provider)
            }
        }
        .pickerStyle(.menu)
        .padding([.horizontal, .bottom])
    }
}
