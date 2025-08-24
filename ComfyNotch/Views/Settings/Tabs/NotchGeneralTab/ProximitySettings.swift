//
//  ProximitySettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/24/25.
//

import SwiftUI

struct ProximitySettingsValues {
    var proximityWidth: Int = 0
    var proximityHeight: Int = 0
}

struct ProximitySettings: View {
    
    
    @Binding var values: ProximitySettingsValues
    @Binding var didChange: Bool
    
    @ObservedObject private var notchStateManager = NotchStateManager.shared
    @ObservedObject private var settings = SettingsModel.shared
    
    private var proximityWidthInitialValue : Int {
        return Int(settings.proximityWidth)
    }
    private var proximityHeightInitialValue: Int {
        return Int(settings.proximityHeight)
    }

    var body: some View {
        VStack {
            proximitySettings
        }
        .onAppear {
            
            values.proximityWidth = Int(settings.proximityWidth)
            values.proximityHeight = Int(settings.proximityHeight)
            
        }
        .onChange(of: [values.proximityWidth, values.proximityHeight]) {
            didChange =
            values.proximityWidth != proximityWidthInitialValue
            || values.proximityHeight != proximityHeightInitialValue
        }
    }
    
    // MARK: - Proximity Settings
    private var proximitySettings: some View {
        VStack(alignment: .leading) {
            ComfySlider(
                value: $values.proximityWidth,
                in: 0...1000,
                label: "Proximity Width"
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
                .padding(.vertical, 8)
            
            ComfySlider(
                value: $values.proximityHeight,
                in: 0...1000,
                label: "Proximity Height"
            )
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            Toggle("Visualize Proximity", isOn: $notchStateManager.shouldVisualizeProximity)
                .toggleStyle(.switch)
                .padding(.horizontal)
                .padding(.bottom, 8)
            /// Always turn off on close
                .onDisappear {
                    notchStateManager.shouldVisualizeProximity = false
                }
        }
    }

}
