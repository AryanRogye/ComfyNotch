//
//  QuickAccessSettingsView+Utils.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct QuickAccessSettingsView_Utils: View {
    
    @ObservedObject private var settings: SettingsModel = .shared
    @State private var isHoveringOverUtils: Bool = false
    
    var body: some View {
        VStack {
            titleView
            
            ComfySection(title: "Options") {
                enableUtilsOption
                enableClipboardListener
            }
        }
    }
    
    // MARK: - Title
    private var titleView: some View {
        HStack {
            Text("Utils Settings")
                .font(.largeTitle)
            Spacer()
        }
    }
    
    private var enableUtilsOption: some View {
        HStack {
            Text("Enable Utils")
            Spacer()
            
            Toggle(isOn: $settings.enableUtilsOption) {}
                .toggleStyle(.switch)
                .disabled(settings.enableClipboardListener)
                .onChange(of: settings.enableUtilsOption) {
                    settings.saveSettings()
                }
        }
        .shadow(color: isHoveringOverUtils ? .red : .black, radius: isHoveringOverUtils ? 3 : 0)
        .overlay(
            Group {
                if isHoveringOverUtils {
                    Text("Turn off Clipboard & Bluetooth first.")
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .transition(.opacity)
                        .offset(y: 24)
                }
            }
        )
        .onHover { hover in
            if settings.enableClipboardListener {
                isHoveringOverUtils = hover
            } else {
                isHoveringOverUtils = false
            }
        }
    }
    
    private var enableClipboardListener: some View {
        HStack {
            Text("Enable Clipboard Listener")
            
            Spacer()
            
            Toggle(isOn: $settings.enableClipboardListener) {}
                .toggleStyle(.switch)
                .onChange(of: settings.enableClipboardListener) {
                    settings.saveSettings()
                    
                    if settings.enableClipboardListener {
                        settings.enableUtilsOption = true
                        ClipboardManager.shared.start()
                    } else {
                        ClipboardManager.shared.stop()
                    }
                    
                    if !settings.enableClipboardListener {
                        settings.enableUtilsOption = false
                    }
                }
        }
    }
}
