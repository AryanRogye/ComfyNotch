import SwiftUI

struct ShortcutView: View {

    @ObservedObject var settings: SettingsModel
    @ObservedObject private var shortcutHandler = ShortcutHandler.shared

    // temp value for modifier
    @State private var selectedModifier: ModifierKey = .command

    var body: some View {
        ComfyScrollView {
            Text("Shortcut Settings")
                .font(.title)
                .padding(.top, 10)
            
            /// Shows all the available shortcuts
            ShortcutRows()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ShortcutView(settings: SettingsModel.shared)
}
