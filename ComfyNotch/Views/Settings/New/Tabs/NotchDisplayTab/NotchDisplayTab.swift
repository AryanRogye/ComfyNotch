//
//  NotchDisplayTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct NotchDisplayTab: View {
    var body: some View {
        ComfyScrollView {
            selectScreen
        }
    }
    
    private var selectScreen: some View {
        ComfySettingsContainer {
            SelectScreenView()
        } header: {
            Text("Select Screen")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
