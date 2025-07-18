//
//  AISettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct AISettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("AI API Key", text: $settings.aiApiKey)
                .textFieldStyle(PlainTextFieldStyle()) // ✅ Removes system styling
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.1))
                )
                .padding()
                .focusable(true)
                .onChange(of: settings.aiApiKey) {
                    settings.saveSettings()
                }
            
            HStack {
                Spacer()
                Button( action: addFromClipboard ) {
                    Text("Add From Clipboard")
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func addFromClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            settings.aiApiKey = clipboardString
            settings.saveSettings()
        }
    }
}
