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
            Text("Metal (GPU Rendering) Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                settings.saveMetalAnimationValues(values: metalSettingsValues)
                metalSettingsChanged = false
            }) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        metalSettingsChanged
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.1)
                    }
                    .foregroundColor(
                        metalSettingsChanged
                        ? Color.red
                        : Color.green
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
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
            
            Button(action: {
                settings.saveOpeningAnimationValues(values: animationSettingsValues)
                openingAnimationSettingsChanged = false
            }) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        openingAnimationSettingsChanged
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.1)
                    }
                    .foregroundColor(
                        openingAnimationSettingsChanged
                        ? Color.red
                        : Color.green
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!openingAnimationSettingsChanged)
            
        }
    }
    
}
