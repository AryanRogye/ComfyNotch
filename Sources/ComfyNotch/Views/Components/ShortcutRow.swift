import SwiftUI

struct ShortcutRows: View {
    @ObservedObject var shortcutHandler = ShortcutHandler.shared

    var body: some View {
        ForEach($shortcutHandler.userShortcuts) { $shortcut in
            ModifierPickerItem(
                name: shortcut.name,
                selected: $shortcut.modifiers,
                key: $shortcut.key
            )
        }
    }
}
