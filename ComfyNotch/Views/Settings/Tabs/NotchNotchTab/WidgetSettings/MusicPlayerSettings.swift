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
    var enableAlbumFlippingAnimation: Bool = true
}

struct MusicPlayerSettings: View {
    
    @EnvironmentObject var settings : SettingsModel
    @Binding var didChange : Bool
    @Binding var values : MusicPlayerSettingsValues
    
    var body: some View {
        VStack {
            pickMusicPlayerStyles
                .padding([.horizontal, .top])
            
            Divider()
                .padding(.vertical, 8)
            
            albumFlipping
                .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)

            showMusicProvider
                .padding(.horizontal)

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
                    .padding([.horizontal, .bottom])
            }
        }
        .onAppear {
            values.showMusicProvider = settings.showMusicProvider
            values.musicController = settings.musicController
            values.overridenMusicProvider = settings.overridenMusicProvider
            values.musicPlayerStyle = settings.musicPlayerStyle
            values.enableAlbumFlippingAnimation = settings.enableAlbumFlippingAnimation
        }
        .onChange(of: values.showMusicProvider) { didValuesChange() }
        .onChange(of: values.musicController) { didValuesChange() }
        .onChange(of: values.overridenMusicProvider) { didValuesChange() }
        .onChange(of: values.musicPlayerStyle) { didValuesChange() }
        .onChange(of: values.enableAlbumFlippingAnimation) { didValuesChange() }
    }
    
    private func didValuesChange() {
        let sM   = values.showMusicProvider             != settings.showMusicProvider
        let mC   = values.musicController               != settings.musicController
        let oMP  = values.overridenMusicProvider        != settings.overridenMusicProvider
        let mPS  = values.musicPlayerStyle              != settings.musicPlayerStyle
        let eAFA = values.enableAlbumFlippingAnimation  != settings.enableAlbumFlippingAnimation
        
        if sM || mC || oMP || mPS || eAFA {
            didChange = true
        }
    }
    
    // MARK: - Pick Music Player Styles
    private var pickMusicPlayerStyles: some View {
        HStack {
            ComfyPickerElement(
                isSelected: values.musicPlayerStyle == .comfy,
                label: "Comfy"
            ) {
                values.musicPlayerStyle = .comfy
            } content: {
                comfyStyle
            }
            
            ComfyPickerElement(
                isSelected: values.musicPlayerStyle == .native,
                label: "Native"
            ) {
                values.musicPlayerStyle = .native
            } content: {
                nativeStyle
            }
        }
    }
    
    private var comfyStyle: some View {
        HStack(alignment: .top) {
            
            VStack {
                materialAlbum()
            }
            .frame(alignment: .leading)
            
            VStack(alignment: .leading, spacing: 3) {
                fakeLettering
                fakeTimeline(width: 50, cornerRadius: 12)
                fakeButtons
            }
            .frame(alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var nativeStyle: some View {
        VStack(alignment: .leading, spacing: 3) {
            
            HStack(alignment: .top, spacing: 3) {
                VStack {
                    materialAlbum(width: 17, height: 17, cornerRadius: 5)
                }
                .frame(alignment: .leading)
                
                VStack(alignment: .leading) {
                    fakeLettering
                }
                .frame(alignment: .leading)
                
            }
            
            fakeTimeline(width: 70, cornerRadius: 12)
            
            /// Simulating  centering, which it does with the 16
            fakeButtons
                .padding(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private func materialAlbum(width: CGFloat = 30, height: CGFloat = 30, cornerRadius: CGFloat = 8) -> some View {
        fakeMaterialBar(width: width, height: height, cornerRadius: cornerRadius)
    }
    private var fakeLettering: some View {
        fakeMaterialBar(width: 50, height: 8)
    }
    private func fakeTimeline(width: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        fakeMaterialBar(width: width, height: 5, cornerRadius: cornerRadius)
    }
    private var fakeButtons: some View {
        HStack {
            fakeMaterialBar(width: 6, height: 6)
            fakeMaterialBar(width: 6, height: 6)
            fakeMaterialBar(width: 6, height: 6)
        }
    }
    
    private func fakeMaterialBar(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThickMaterial)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.05), lineWidth: 1)
            )
    }
    
    // MARK: - Album Flipping
    private var albumFlipping: some View {
        HStack {
            Text("Enable Album Flipping Animation")
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: $values.enableAlbumFlippingAnimation)
                .labelsHidden()
                .toggleStyle(.switch)
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
    }
}
