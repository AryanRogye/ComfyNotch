//
//  UtilsSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct UtilsSettingsValues: Equatable {
    var enableUtilsOption: Bool = false
    var enableClipboardListener: Bool = false
}

public struct UtilsSettingsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @Binding var v: UtilsSettingsValues
    
    @State private var isHoveringOverUtils: Bool = false
    
    @State private var hasAppeared = false
    @State private var originalState: UtilsSettingsValues = .init()
    
    init(didChange: Binding<Bool>, values: Binding<UtilsSettingsValues>) {
        self._didChange = didChange
        self._v = values
    }
    
    public var body: some View {
        VStack {
            enableUtilsOption
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider().groupBoxStyle()
            
            enableClipboardListener
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
    
    private var enableUtilsOption: some View {
        HStack {
            Toggle("Enable Utils",isOn: $v.enableUtilsOption)
                .toggleStyle(.switch)
                .disabled(v.enableClipboardListener)
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
            if v.enableClipboardListener {
                isHoveringOverUtils = hover
            } else {
                isHoveringOverUtils = false
            }
        }
        .onAppear {
            v.enableClipboardListener = settings.enableClipboardListener
            v.enableUtilsOption = settings.enableUtilsOption
            
            originalState = UtilsSettingsValues(
                enableUtilsOption: settings.enableUtilsOption,
                enableClipboardListener: settings.enableClipboardListener
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
    
    private var enableClipboardListener: some View {
        HStack {
            Text("Enable Clipboard Listener")
            
            Spacer()
            
            Toggle(isOn: $v.enableClipboardListener) {}
                .toggleStyle(.switch)
        }
    }
}
