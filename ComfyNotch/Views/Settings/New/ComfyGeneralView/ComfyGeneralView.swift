//
//  ComfyGeneralView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/16/25.
//

import SwiftUI

struct ComfyGeneralView: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        ComfyScrollView {
            ComfySettingsContainer {
            } header: {
            }
        }
    }
}
