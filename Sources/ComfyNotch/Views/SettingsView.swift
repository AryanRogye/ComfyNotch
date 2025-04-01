import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding()

            Text("Adjust your settings here.")
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
