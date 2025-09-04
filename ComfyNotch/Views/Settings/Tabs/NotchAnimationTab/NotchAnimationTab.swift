//
//  NotchAnimationTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI


struct NotchAnimationTab : View {
    
    @EnvironmentObject var settings: SettingsModel
    
    @State private var openingAnimationSettingsChanged: Bool = false
    @State private var animationSettingsValues = OpeningAnimationSettingsValues()
    
    @State private var metalSettingsChanged: Bool = false
    @State private var metalSettingsValues = MetalAnimationValues()
    
    var body: some View {
        ComfyScrollView {
            openingAnimationSettings
            
            metalSettings
        }
    }
    
    private var metalSettings: some View {
        ComfySettingsContainer {
            MetalAnimations(
                values: $metalSettingsValues,
                didChange: $metalSettingsChanged
            )
        } header: {
            VStack(alignment: .leading, spacing: 3) {
                Text("Metal (GPU Rendering) Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Label("Uses additional system resources", systemImage: "info.circle")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .labelStyle(.titleAndIcon)
            }

            Spacer()
            

            ComfyButton(title: "Save", $metalSettingsChanged) {
                settings.saveMetalAnimationValues(values: metalSettingsValues)
                metalSettingsChanged = false
            }
        }
    }
    
    private var openingAnimationSettings: some View {
        ComfySettingsContainer {
            OpeningAnimation(
                values: $animationSettingsValues,
                didChange: $openingAnimationSettingsChanged
            )
        } header: {
            Text("Notch Opening Animation")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            ComfyButton(title: "Save", $openingAnimationSettingsChanged) {
                settings.saveOpeningAnimationValues(values: animationSettingsValues)
                openingAnimationSettingsChanged = false
            }
        }
    }
    
}
