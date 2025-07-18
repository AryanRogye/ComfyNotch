//
//  OpeningAnimation.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct OpeningAnimation: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @State private var openingAnimation: String = "iOS"
    
    private var initialOpeningAnimation: String {
        settings.openingAnimation
    }
    
    var body: some View {
        VStack {
            openingAnimationPicker
        }
        .onAppear {
            openingAnimation = initialOpeningAnimation
        }
    }
    
    private var openingAnimationPicker: some View {
        VStack {
            HStack(spacing: 0) {
                Picker("Pick how you want the notch to open.", selection: $openingAnimation) {
                    Text("Spring Animation").tag("spring")
                    Text("iOS Animation").tag("iOS")
                }
                .pickerStyle(.menu)
                .tint(.accentColor)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
