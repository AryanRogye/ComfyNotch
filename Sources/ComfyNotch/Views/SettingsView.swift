import SwiftUI

class SettingsModel: ObservableObject {
    static let shared = SettingsModel() // Singleton for global access
}
struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding()

            Text("Adjust your settings here.")
                .padding()

            .padding()

            Button(action: {
                NSApplication.shared.keyWindow?.close()
            }) {
                Text("Close")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: closeWindow) {
                Text("Close ComfyNotch")
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    // close the entire running app
    func closeWindow() {
        NSApplication.shared.keyWindow?.close()
        NSApp.terminate(nil)
    }
}
