import AppKit
import SwiftUI


struct NotesWidget_ : View, SwiftUIWidget {

    var name: String = "UserNotesWidget"
    private var buttons: [String] = ["1", "2", "3"]

    @ObservedObject var model = NotesWidgetModel()  // Using your model

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                ForEach(buttons, id: \.self) { button in
                    Button(action: {
                        model.selectedButton = button
                        model.loadNotes()  // Load the note for the selected button
                    }) {
                        Text(button)
                            .frame(maxWidth: .infinity)
                            .padding(5)
                            .foregroundColor(.white)
                            .background(button == model.selectedButton ? Color.blue : Color.gray)
                            .cornerRadius(5)
                    }
                }
            }
            .frame(width: 40)

            TextEditor(text: $model.text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(8)
                .padding(3)
                .onChange(of: model.text) { _ in
                    model.saveNotes()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

struct NotesWidget__: View, SwiftUIWidget {
    var name: String = "NotesWidget"

    // Buttons to switch between notes
    // private var buttons: [String] = ["1", "2", "3"]

    // @ObservedObject var model = NotesWidgetModel()  // Using your model

    var body: some View {
        HStack {
            Text("Hello")   
                .font(.system(size: 14))
                .foregroundColor(.white)
            // VStack(spacing: 0) {
            //     ForEach(buttons, id: \.self) { button in
            //         Button(action: {
            //             model.selectedButton = button
            //             model.loadNotes()  // Load the note for the selected button
            //         }) {
            //             Text(button)
            //                 .frame(maxWidth: .infinity)
            //                 .padding(5)
            //                 .foregroundColor(.white)
            //                 .background(button == model.selectedButton ? Color.blue : Color.gray)
            //                 .cornerRadius(5)
            //         }
            //     }
            // }
            // .frame(width: 40)

            // TextEditor(text: $model.text)
            //     .font(.system(size: 14))
            //     .foregroundColor(.white)
            //     .background(Color.black)
            //     .cornerRadius(8)
            //     .padding(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class NotesWidgetModel : ObservableObject {
    @Published var text: String = ""
    @Published var selectedButton: String = "1"

    init() {
        loadNotes()  // Load initial note
    }

    func loadNotes() {
        let savedText = UserDefaults.standard.string(forKey: "\(selectedButton)_content") ?? "Hello, this is a test note.\nYou can edit this text."
        text = savedText
    }

    func saveNotes() {
        UserDefaults.standard.set(text, forKey: "\(selectedButton)_content")
    }
}

struct NotesTextView: View {
    @Binding var text: String
    @Binding var selectedButton: String

    // we will have 3 buttons for 3 notes, the butttons will be used to switch between the notes
    private var buttons: [String] = ["1", "2", "3"]

    public init(text: Binding<String>, selectedButton: Binding<String>) {
        self._text = text
        self._selectedButton = selectedButton
    }

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                ForEach(buttons, id: \.self) { button in
                    Button(action: {
                        selectedButton = button
                    }) {
                        Text(button)
                            .frame(minHeight: 0)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .foregroundColor(.white)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 40)
            .frame(maxHeight: .infinity)

            TextEditor(text: $text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .background(Color.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(3)
    }
}

class NotesWidget: Widget {

    var name: String = "Notes"
    var view: NSView

    var notes: String {
        didSet {
            saveNotes(notes, 
                      at: selectedButton)
        }
    }

    var selectedButton: String {
        didSet {
            notes = loadNotes(at: selectedButton)
            update()
        }
    }


    init() {
        selectedButton = "1"
        notes = UserDefaults.standard.string(forKey: "\(selectedButton)_content") ?? "Hello, this is a test note.\nYou can edit this text."
        view = NSView()

        view = NSHostingView(rootView: NotesTextView(
            text: Binding(
                get: { self.notes },
                set: { self.notes = $0 }
            ),
            selectedButton: Binding(
                get: { self.selectedButton },
                set: { self.selectedButton = $0 }
            )
        ))
    
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false

        // Update the rootView after the initial setup.
        if let hostingView = view as? NSHostingView<NotesTextView> {
            hostingView.rootView = NotesTextView(text: Binding(
                                                    get: { self.notes },
                                                    set: { self.notes = $0}
                                                 ),
                                                 selectedButton: Binding(
                                                    get: { self.selectedButton.description },
                                                    set: { self.selectedButton = $0 }))}

        // ✅ Force the view to expand to the max height of the stackView
        view.setContentHuggingPriority(.defaultLow, 
                                       for: .horizontal)

        view.setContentHuggingPriority(.defaultLow, 
                                       for: .vertical)

        view.setContentCompressionResistancePriority(.defaultLow, 
                                                     for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, 
                                                     for: .vertical)
    }

    private func loadNotes(at index: String) -> String {
        return UserDefaults.standard.string(forKey: "\(index)_content") ?? "Hello, this is a test note.\nYou can edit this text."
    }

    private func saveNotes(_ notes: String, at index: String) {
        UserDefaults.standard.set(notes, 
                                  forKey: "\(index)_content")
    }

    func update() {
        // Update the SwiftUI view if necessary.
        if let hostingView = view as? NSHostingView<NotesTextView> {
            hostingView.rootView = NotesTextView(text: Binding(
                                                    get: { self.notes },
                                                    set: { self.notes = $0 }
                                                 ),
                                                 selectedButton: Binding(
                                                     get: { self.selectedButton.description },
                                                     set: { self.selectedButton = $0 }))}
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