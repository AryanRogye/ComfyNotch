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

    }

    private func saveNotes(_ notes: String) {
        UserDefaults.standard.set(notes, forKey: "notesWidget_content")
    }

    func setupInternalConstraints() {
        guard view.superview != nil else { return } // Exit if superview is nil

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: view.superview!.leadingAnchor, constant: 10),
            view.trailingAnchor.constraint(equalTo: view.superview!.trailingAnchor, constant: -10),
            view.topAnchor.constraint(equalTo: view.superview!.topAnchor, constant: 10),
            view.bottomAnchor.constraint(equalTo: view.superview!.bottomAnchor, constant: -10)
        ])
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