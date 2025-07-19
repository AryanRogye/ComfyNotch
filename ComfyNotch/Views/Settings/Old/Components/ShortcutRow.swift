import SwiftUI

struct ShortcutRowss: View {
    @ObservedObject var shortcutHandler = ShortcutHandler.shared

    var body: some View {
        ForEach($shortcutHandler.userShortcuts) { $shortcut in
            ModifierPickerItemm(
                name: shortcut.name,
                selected: $shortcut.modifiers,
                key: $shortcut.key
            )
        }
    }
}
