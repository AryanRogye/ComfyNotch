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
    var modifier: ModifierKey
    /// The key of the shortcut is what is pressed with the modifier, this doesnt always
    /// necessarily mean that the key will always be inputted for a userShortcut, this is
    /// because, certain actions like "Hide Dock When Hover", its much easier to press with just
    /// a modifier button and not with a key.
    var key: String?
}

extension UserShortcut {
    static var defaultShortcuts: [UserShortcut] = [
        UserShortcut(name: "Hover Hide", modifier: .command),
        UserShortcut(name: "Open Settings", modifier: .command, key: "s"),
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
            let matchesModifier = event.modifierFlags.contains(shortcut.modifier.eventFlag)
            let matchesKey = shortcut.key == nil || event.charactersIgnoringModifiers?.lowercased() == shortcut.key?.lowercased()

            if matchesModifier && matchesKey {
                self.pressedShortcut = shortcut.name
                print("Shortcut matched → \(shortcut.name) [\(shortcut.modifier.rawValue) + \(shortcut.key ?? "")]")
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
            return activeModifiers.contains(shortcut.modifier)
        }

        // If it's a modifier + key combo, match recent pressed name
        return pressedShortcut == name
    }

    func updateModifier(for name: String, to newModifier: ModifierKey) {
        // find the relevant shortcut
        if let index = userShortcuts.firstIndex(where: { $0.name == name }) {
            // update its modifier
            userShortcuts[index].modifier = newModifier
            print("Updated \(name) to modifier \(newModifier.rawValue)")
        }
    }
    
    private func handleModifierEvent(_ event: NSEvent) {
        let currentFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        lastFlags = currentFlags

        for shortcut in userShortcuts where shortcut.key == nil {
            let isPressedNow = currentFlags.contains(shortcut.modifier.eventFlag)
            let wasPressedBefore = activeModifiers.contains(shortcut.modifier)
            // Key just pressed
            if isPressedNow && !wasPressedBefore {
                activeModifiers.insert(shortcut.modifier)
                self.pressedShortcut = shortcut.name
                // print("🔹 Modifier down → \(shortcut.name) [\(shortcut.modifier.rawValue)]")
            }
            // Key just released
            if !isPressedNow && wasPressedBefore {
                activeModifiers.remove(shortcut.modifier)
                // print("🔻 Modifier up → \(shortcut.modifier.rawValue)")
            }
        }
    }
}
