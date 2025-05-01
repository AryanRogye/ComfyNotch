import AppKit
import ApplicationServices

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
        /// Local Shortcut used to hide both the panels, this is just in case you want to
        /// use the toolbar like in xcode where its super heavy up in the toolbar and my panel
        /// hides it
        /// See: [HoverHandler](file:Sources/ComfyNotch/Handlers/HoverHandler.swift)
        UserShortcut(name: "Hover Hide", modifiers: [.command]),
        /// Global Shortcut used to open the settings page from anywhere, this is useful
        /// if the app settings is not reachable but the user needs to quit out of the app
        /// sometimes the "Hover Hide" may not work and the user rage quits and leaves
        UserShortcut(name: "Open Settings", modifiers: [.command], key: "s"),
        /// Global Shortcut used to reload the panels, I would think if some monitor switching,
        /// or some other issue happens then it can easily be fixable with just a:
        ///     Command Control Option R
        /// Display Pulled From -> [DisplayHandler](file:Sources/Handlers/DisplayHandler.swift)
        UserShortcut(name: "Reload App", modifiers: [.command, .control, .option], key: "r")
    ]
}

class ShortcutHandler: ObservableObject {

    static let shared = ShortcutHandler()

    private var localMonitor: Any?
    @Published var pressedShortcut: String?

    @Published var userShortcuts: [UserShortcut] = UserShortcut.defaultShortcuts

    var activeModifiers: Set<ModifierKey> = []
    private var lastFlags: NSEvent.ModifierFlags = []

    private init() {
    }

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
    
    /// This will only run if the "EXACT" Key is pressed, for example
    /// If the modifier is command + control then key is a:
    ///     command + control + option then key = a will not work
    /// This allows for multiple usecases
    private func handleKeyEvent(_ event: NSEvent) {
        for shortcut in userShortcuts {
            let shortcutModifiers = shortcut.modifiers
            let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            /// Reducing is what allows it to match perfectly, to allow the vice versa change to .allStaisfy
            let shortcutModifierFlags = shortcutModifiers.reduce(into: NSEvent.ModifierFlags()) { flags, modifier in
                flags.insert(modifier.eventFlag)
            }
            
            let matchesModifiersExactly = eventModifiers == shortcutModifierFlags
            let matchesKey = shortcut.key == nil || (event.charactersIgnoringModifiers?.lowercased() == shortcut.key?.lowercased())
            
            if matchesModifiersExactly && matchesKey {
                self.pressedShortcut = shortcut.name
                debugLog("Shortcut matched → \(shortcut.name) [\(shortcut.modifiers.map(\.rawValue).joined(separator: " + ")) + \(shortcut.key ?? "")]")
                
                handleShortcutAction(for: shortcut.name)
            }
        }
    }
    
    private func handleShortcutAction(for name: String) {
        switch name {
        case "Open Settings":
            SettingsWidgetModel.shared.action()
        case "Reload App":
            DisplayHandler.shared.restartApp()
        default:
            break
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
            debugLog("Updated \(name) to modifier \(newModifier.rawValue)")
        }
    }

    private func handleModifierEvent(_ event: NSEvent) {
        let currentFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        lastFlags = currentFlags

        for shortcut in userShortcuts where shortcut.key == nil {
            // Build the expected flags from the shortcut modifiers
            let shortcutModifierFlags = shortcut.modifiers.reduce(into: NSEvent.ModifierFlags()) { flags, modifier in
                flags.insert(modifier.eventFlag)
            }

            // Strict check: must match exactly
            let matchesModifiersExactly = currentFlags == shortcutModifierFlags

            let wasActiveBefore = shortcut.modifiers.allSatisfy { modifier in
                activeModifiers.contains(modifier)
            }

            if matchesModifiersExactly && !wasActiveBefore {
                activeModifiers.formUnion(shortcut.modifiers) // insert all modifiers into activeModifiers
                self.pressedShortcut = shortcut.name
//                debugLog("🔹 Modifier down → \(shortcut.name) [\(shortcut.modifiers.map(\.rawValue).joined(separator: " + "))]")
            }
            if !matchesModifiersExactly && wasActiveBefore {
                activeModifiers.subtract(shortcut.modifiers) // remove all modifiers from activeModifiers
//                debugLog("🔻 Modifier up → \(shortcut.modifiers.map(\.rawValue).joined(separator: " + "))")
            }
        }
    }
}
