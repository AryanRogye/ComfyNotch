//
//  QuickAccessSettingsView+Utils.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct QuickAccessSettingsView_Utils: View {
    var body: some View {
        VStack {
            titleView
        }
    }
    
    // MARK: - Title
    private var titleView: some View {
        HStack {
            Text("Utils Settings")
                .font(.largeTitle)
            Spacer()
        }
    }

}
