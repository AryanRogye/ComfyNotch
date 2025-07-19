//
//  OpeningAnimation.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct OpeningAnimationSettingsValues {
    var openingAnimation: String = "iOS"
}

struct OpeningAnimation: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    @Binding var didChange: Bool
    @Binding var v : OpeningAnimationSettingsValues
    
    init(values: Binding<OpeningAnimationSettingsValues>, didChange: Binding<Bool> ) {
        self._didChange = didChange
        self._v = values
    }
    
    private var initialOpeningAnimation: String {
        settings.openingAnimation
    }
    
    var body: some View {
        VStack {
            openingAnimationPicker
        }
        .onAppear {
            v.openingAnimation = initialOpeningAnimation
        }
        .onChange(of: [v.openingAnimation]) {
            didChange =
            v.openingAnimation != initialOpeningAnimation
        }
    }
    
    private var openingAnimationPicker: some View {
        VStack {
            HStack(spacing: 0) {
                Picker("Notch Opening Style", selection: $v.openingAnimation) {
                    Text("Spring").tag("spring")
                    Text("iOS-style").tag("iOS")
                }
                .pickerStyle(.menu)
                .tint(.accentColor)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
