import SwiftUI

struct ShortcutView: View {

    @ObservedObject var settings: SettingsModel
    @StateObject private var shortcutHandler = ShortcutHandler.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Listen for Shortcuts")
                Text(shortcutHandler.pressedShortcut ?? "No shortcut pressed")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .onAppear {
            shortcutHandler.startListening()
        }
    }
}
