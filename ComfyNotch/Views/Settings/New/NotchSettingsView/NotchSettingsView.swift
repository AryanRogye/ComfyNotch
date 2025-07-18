//
//  NotchSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

/// Fully RE-DONE Settings View for ComfyNotch
/// NO AI COPY PASTE HERE

struct NotchSettingsView: View {
    
    var body: some View {
        VStack {
            ComfyScrollView {
                currentWidgetsDisplay
                selectWidgetsDisplay
            }
        }
    }
    
    private var currentWidgetsDisplay: some View {
        ComfySettingsContainer {
            CurrentWidgetsDisplayView()
        } header: {
            Text("Currently Selected Widgets")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
        }
    }
    
    private var selectWidgetsDisplay: some View {
        ComfySettingsContainer {
            SelectWidgetsView()
        } header: {
            Text("Select Widgets")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
        }
    }
    
}
