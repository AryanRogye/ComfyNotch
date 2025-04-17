import AppKit

enum ModifierKey: String, CaseIterable, Identifiable {
    case command = "⌘ Command"
    case control = "^ Control"
    case option = "⌥ Option"
    case shift = "⇧ Shift"

    var id: String { rawValue }
}

/// This is the userShortcut struct, this is used to create a shortcut for the user
struct UserShortcut: Identifiable {
    var id = UUID()
    /// Name of the shortcut, this is what will be displayed in the UI
    var name: String
    /// The modifier is the key that is pressed with the shortcut, this is always going to be activated
    /// before the key, this means we always check the modifier first, then the key, this case no accidental
    /// "Key" then "Modifier" presses will be registered.
    /// - Mark: This is new, I changed this to a set because we can have multiple modifiers imagine that shit
    ///         we can have command + + control + option + shift + key
    ///         The Set is my design choice, I couldve went with a array but its imo the best way to not
    ///         have to check for duplicates, and also its easier to check if a modifier is in the set
    var modifiers: Set<ModifierKey> = []
    /// The key of the shortcut is what is pressed with the modifier, this doesnt always
    /// necessarily mean that the key will always be inputted for a userShortcut, this is
    /// because, certain actions like "Hide Dock When Hover", its much easier to press with just
    /// a modifier button and not with a key.
    var key: String?
}

extension UserShortcut {
    static var defaultShortcuts: [UserShortcut] = [
        UserShortcut(name: "Hover Hide", modifiers: [.command]),
        UserShortcut(name: "Open Settings", modifiers: [.command], key: "s")
    ]
}

class ShortcutHandler: ObservableObject {

    static let shared = ShortcutHandler()

    private var localMonitor: Any?
    @Published var pressedShortcut: String?

    @Published var userShortcuts: [UserShortcut] = UserShortcut.defaultShortcuts

    var activeModifiers: Set<ModifierKey> = []
    private var lastFlags: NSEvent.ModifierFlags = []

    private init() {}

    func startListening() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .keyDown {
                self.handleKeyEvent(event)
            } else if event.type == .flagsChanged {
                self.handleModifierEvent(event)
            }
            return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.handleKeyEvent(event)
        }
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            self.handleModifierEvent(event)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        for shortcut in userShortcuts {
            let shortcutModifiers = shortcut.modifiers
            let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            let allModifiersPressed = shortcutModifiers.allSatisfy { modifier in
                eventModifiers.contains(modifier.eventFlag)
            }

            let matchesKey = shortcut.key == nil || (event.charactersIgnoringModifiers?.lowercased() == shortcut.key?.lowercased())

            if allModifiersPressed && matchesKey {
                self.pressedShortcut = shortcut.name
                print("Shortcut matched → \(shortcut.name) [\(shortcut.modifiers.map(\.rawValue).joined(separator: " + ")) + \(shortcut.key ?? "")]")
            }
        }
    }

    /// Usage:
    /// if ShortcutHandler.shared.isShortcutActive("Hover Hide") {
    ///     // perform hover hide logic or animation
    /// }
    func isShortcutActive(_ name: String) -> Bool {
        guard let shortcut = userShortcuts.first(where: { $0.name == name }) else {
            return false
        }

        // Modifier-only shortcut check
        if shortcut.key == nil {
            return activeModifiers.contains(shortcut.modifiers)
        }

        // If it's a modifier + key combo, match recent pressed name
        return pressedShortcut == name
    }

    func updateModifier(for name: String, to newModifier: ModifierKey) {
        if let index = userShortcuts.firstIndex(where: { $0.name == name }) {
            userShortcuts[index].modifiers = [newModifier] // <<< wrap in array or set
            print("Updated \(name) to modifier \(newModifier.rawValue)")
        }
    }

    private func handleModifierEvent(_ event: NSEvent) {
        let currentFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        lastFlags = currentFlags

        for shortcut in userShortcuts where shortcut.key == nil {
            let allModifiersPressed = shortcut.modifiers.allSatisfy { modifier in
                currentFlags.contains(modifier.eventFlag)
            }

            let wasActiveBefore = shortcut.modifiers.allSatisfy { modifier in
                activeModifiers.contains(modifier)
            }

            if allModifiersPressed && !wasActiveBefore {
                activeModifiers.formUnion(shortcut.modifiers) // insert all modifiers into activeModifiers
                self.pressedShortcut = shortcut.name
                // print("🔹 Modifier down → \(shortcut.name) [\(shortcut.modifiers.map(\.rawValue).joined(separator: " + "))]")
            }
            if !allModifiersPressed && wasActiveBefore {
                activeModifiers.subtract(shortcut.modifiers) // remove all modifiers from activeModifiers
                // print("🔻 Modifier up → \(shortcut.modifiers.map(\.rawValue).joined(separator: " + "))")
            }
        }
    }
}
