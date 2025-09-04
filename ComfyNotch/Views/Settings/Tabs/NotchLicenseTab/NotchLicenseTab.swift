//
//  NotchLicenseTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct NotchLicenseTab: View {
    @State private var licenseText: String = ""
    
    var body: some View {
        ComfyScrollView {
            ComfySettingsContainer {
                Text(licenseText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .textSelection(.enabled)
            }
            .onAppear { loadLicense() }
            .padding(.bottom, 32)
        }
    }
    
    private func loadLicense() {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil) {
            licenseText = (try? String(contentsOf: url)) ?? "Could not load license."
        } else {
            licenseText = "License file not found."
        }
    }
}
