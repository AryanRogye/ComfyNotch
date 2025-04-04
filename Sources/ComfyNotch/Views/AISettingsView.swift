import SwiftUI


struct AISettingsView: View {
    @ObservedObject var settings: SettingsModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("AI API Key", text: $settings.ai_api_key, onCommit: {
                    settings.saveSettings()
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focusable(true)
                Text("No Persistent Storage Sorry😓 (For Now....)")
                    .font(.footnote)
                    .padding()
            }
        }
    }
}