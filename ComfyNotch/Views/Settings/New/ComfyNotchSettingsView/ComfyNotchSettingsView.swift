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
    var body: some View {
        ComfyScrollView {
            
            
            // MARK: - Closed Notch Settings
            ComfySettingsContainer {
                ComfyNotchSettingsView_OpenNotchSettings()
            } header: {
                Text("Open")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
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
