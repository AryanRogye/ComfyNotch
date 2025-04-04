import SwiftUI


struct AISettingsView: View {
    @ObservedObject var settings: SettingsModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("AI API Key", text: $settings.ai_api_key)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focusable(true)
            }
        }
    }
}