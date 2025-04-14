import AppKit

enum ModifierKey: String, CaseIterable, Identifiable {
    case command = "⌘ Command"
    case control = "^ Control"
    case option = "⌥ Option"
    case shift = "⇧ Shift"

    var id: String { rawValue }
}

class ShortcutHandler: ObservableObject {

    static let shared = ShortcutHandler()
    private var localMonitor: Any?
    @Published var pressedShortcut: String?

    private init() {

    }

    func startListening() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.handleKeyEvent(event)
            return event
        }
    }

    private func isCommand(for event: NSEvent) -> Bool {
        return event.modifierFlags.contains(.command)
    }

    private func isKey(for event: NSEvent, key: String) -> Bool {
        return event.charactersIgnoringModifiers == key
    }

    private func handleKeyEvent(_ event: NSEvent) {
        if isCommand(for: event) && isKey(for: event, key: "n") {
            self.pressedShortcut = "new"
            print("⌘ + N was pressed")
        }

        if  event.modifierFlags.contains(.command) &&
            event.modifierFlags.contains(.shift) &&
            event.charactersIgnoringModifiers == "w" {

                self.pressedShortcut = "close"
                print("⌘ + Shift + W was pressed")
        }
    }
}
