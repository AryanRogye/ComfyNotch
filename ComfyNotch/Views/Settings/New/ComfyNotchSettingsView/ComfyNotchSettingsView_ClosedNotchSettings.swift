//
//  ComfyNotchSettingsView_ClosedNotchSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ComfyNotchSettingsView_ClosedNotchSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    
    @State private var hoverTargetMode : HoverTarget = .none
    @State private var fallbackHeight: Int = 0
    
    private var hoverTargetModeInitialValue: HoverTarget {
        settings.hoverTargetMode
    }
    private var fallbackHeightInitialValue: Int {
        Int(settings.notchMinFallbackHeight)
    }
    
    var body: some View {
        VStack {
            notchShapeClosed
            
            fallbackHeightSettings
            
            hoverSettings
        }
        .onAppear {
            hoverTargetMode = settings.hoverTargetMode
            fallbackHeight = Int(settings.notchMinFallbackHeight)
        }
        .onChange(of: hoverTargetMode) {
            didChange = hoverTargetMode != hoverTargetModeInitialValue
            || fallbackHeight != fallbackHeightInitialValue
        }
    }
    
    
    // MARK: - Notch Shape Closed
    private var notchShapeClosed: some View {
        /// Notch Shape
        VStack(spacing: 0) {
            HStack {
                CompactAlbumWidget()
                    .padding(.leading, 5)
                
                Spacer()
                
                MovingDotsView()
            }
        }
        .padding(.horizontal, 7)
        .frame(width: 320, height: 38)
        // MARK: - Actual Notch Shape
        .background(
            ComfyNotchShape(topRadius: 8, bottomRadius: 14)
                .fill(Color.black)
        )
    }
    
    
    // MARK: - Fallback Height Settings
    private var fallbackHeightSettings: some View {
        VStack(alignment: .leading) {
            ComfySlider(
                value: $fallbackHeight,
                in: settings.notchHeightMin...settings.notchHeightMax,
                label: "Notch Height Fallback"
            )
            /// TODO: 0 Point is too far to the left
                
            Text("""
                This is the fallback height for the notch if its ever 0, SafeArea doesnt exist in Intel Macs.
                """)
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Hover Settings
    private var hoverSettings: some View {
        VStack {
            HStack {
                Text("Hover Activation Area")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Hover Target", selection: $hoverTargetMode) {
                    ForEach(HoverTarget.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding()
    }
}
