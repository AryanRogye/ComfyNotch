//
//  NotchAnimationTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI


struct NotchAnimationTab : View {
    
    @State private var openingAnimationSettingsChanged: Bool = false
    @State private var metalSettingsChanged: Bool = false
    
    var body: some View {
        ComfyScrollView {
            openingAnimationSettings
            
            metalSettings
        }
    }
    
    private var metalSettings: some View {
        ComfySettingsContainer {
            MetalAnimations(
                didChange: $metalSettingsChanged
            )
        } header: {
            Text("Metal (GPU Rendering) Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var openingAnimationSettings: some View {
        ComfySettingsContainer {
            OpeningAnimation(
                didChange: $openingAnimationSettingsChanged
            )
        } header: {
            Text("Notch Opening Animation")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
}
