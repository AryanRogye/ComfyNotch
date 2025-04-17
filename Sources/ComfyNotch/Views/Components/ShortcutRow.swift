import SwiftUI

struct ShortcutRows: View {
    @ObservedObject var shortcutHandler = ShortcutHandler.shared

    var body: some View {
        ForEach($shortcutHandler.userShortcuts) { $shortcut in
            // If it's "Hover Hide"
            if shortcut.name == "Hover Hide" {
                ModifierPickerItem(
                    name: "Hover Hide",
                    selected: $shortcut.modifier
                )
            }
            // If it's "Open Settings"
            else if shortcut.name == "Open Settings" {
                ModifierPickerItem(
                    name: "Open Settings",
                    selected: $shortcut.modifier
                )
            }
        }
    }
}
