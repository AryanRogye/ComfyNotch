import SwiftUI
import AppKit

struct AISettingsView: View {
    @ObservedObject var settings: SettingsModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("AI API Key", text: $settings.aiApiKey, onCommit: {
                    settings.saveSettings()
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focusable(true)
                Button( action: addFromClipboard ) {
                    Text("Add From Clipboard")
                }
            }
        }
    }

    func addFromClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            settings.aiApiKey = clipboardString
        }
    }
}

#Preview {
    AISettingsView(settings: SettingsModel.shared)
}
