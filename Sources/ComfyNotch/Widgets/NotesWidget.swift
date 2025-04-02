import AppKit
import SwiftUI


struct NotesTextView: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .background(Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

class NotesWidget: Widget {

    var name: String = "Notes"
    var view: NSView

    var notes: String {
        didSet {
            saveNotes(notes)
        }
    }

    init() {
        notes = UserDefaults.standard.string(forKey: "notesWidget_content") ?? "Hello, this is a test note.\nYou can edit this text."

        view = NSHostingView(rootView: NotesTextView(text: .constant(notes)))
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false

        // Update the rootView after the initial setup.
        if let hostingView = view as? NSHostingView<NotesTextView> {
            hostingView.rootView = NotesTextView(text: Binding(
                get: { self.notes },
                set: { self.notes = $0 }
            ))
        }

        // ✅ Force the view to expand to the max height of the stackView
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    }

    private func saveNotes(_ notes: String) {
        UserDefaults.standard.set(notes, forKey: "notesWidget_content")
    }

    func loadNotes() -> String {
        return UserDefaults.standard.string(forKey: "notesWidget_content") ?? "Hello, this is a test note.\nYou can edit this text."
    }

    func update() {
        // Update the SwiftUI view if necessary.
        if let hostingView = view as? NSHostingView<NotesTextView> {
            hostingView.rootView = NotesTextView(text: Binding(
                get: { self.notes },
                set: { self.notes = $0 }
            ))
        }
    }

    func show() {
        view.isHidden = false
        DispatchQueue.main.async {
            self.view.window?.makeFirstResponder(self.view)
        }
    }

    func hide() {
        view.isHidden = true
    }
}