//
//  ComfyNotchSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

/// Fully RE-DONE Settings View for ComfyNotch
/// NO AI COPY PASTE HERE

struct ComfyNotchSettingsView: View {
    
    @State private var openSettingsChanged: Bool = false
    
    var body: some View {
        ComfyScrollView {
            // MARK: - Closed Notch Settings
            ComfySettingsContainer {
                ComfyNotchSettingsView_OpenNotchSettings(
                    didChange: $openSettingsChanged
                )
            } header: {
                Text("Open")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                if openSettingsChanged {
                    Button(action: {}) {
                        Text("Save")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
            }
            
            // MARK: - Open Notch Settings
            ComfySettingsContainer {
            } header: {
                Text("Closed")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            
            
        }
    }
}
