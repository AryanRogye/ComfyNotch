import AppKit
import SwiftUI

enum WidgetViewState {
    case viewList
    case addNewNote
    case editor(Note)
}
struct NotesWidget: View, Widget {

    var name: String = "NotesWidget"
    private var buttons: [String] = ["1", "2", "3"]

    @ObservedObject var model = NotesWidgetModel()  // Using your model

    @State var currentFontSize: CGFloat = 14
    @State var showFontControls: Bool = false

    @State private var addNewNoteOverlayIsPresented: Bool = false
    @State private var newNoteName: String = ""

    @State private var showingContentForNote: Bool = false

    @State private var currentView: WidgetViewState = .viewList
    @ObservedObject private var hoverState = WidgetHoverState.shared

    var body: some View {
        ZStack {
            switch currentView {
                case .addNewNote:
                    newNoteView()
                case .viewList:
                    showListView()
                case .editor(let note):
                    showEditorView(note: note)
            }
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onHover { hovering in
            hoverState.isHoveringOverEventWidget = hovering
        }
    }

    @ViewBuilder
    func showEditorView(note: Note?) -> some View {
        if let note = note {
            VStack {
                HStack {
                    Button(action: { 
                            /// Save the note
                            model.updateContent(for: note.id, newContent: model.text)
                            model.text = ""
                            // Close the editor and go back to the list
                            currentView = .viewList 
                        }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .padding([.leading, .top], 8)
                    Spacer()
                // Placeholder content so it forces height
                Text("Editor for \(note.name)")
                    .foregroundColor(.white)
                    .padding()
                }

                Spacer()

                TextEditor(text: $model.text)
                    .font(.system(size: currentFontSize))
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .background(Color.black.opacity(0.1)) // Just for debug
            .onAppear {
                model.selectedNoteID = note.id
                model.text = note.content
            }
        } else {
            Text("No note selected")
                .foregroundColor(.gray)
        }
    }


    @ViewBuilder
    func showListView() -> some View {
        VStack {
            HStack {
                /// We wanna cool search bar here
                Spacer()
                Button(action: { currentView = .addNewNote } ) {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding([.trailing, .top], 3)
            }
            /// Default 3 notes
            ScrollView(.vertical, showsIndicators: true) {
                ForEach(model.notes) { note in
                    Button(action: {
                        currentView = .editor(note)
                    }) {
                        HStack {
                            Text(note.name)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2)
                                .foregroundColor(.white)
                            Spacer()
                                Button(action: { model.deleteNote(note) } ) {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                                .buttonStyle(.plain)
                        }
                    }
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 10)
                }
            }
        }
    }

    @ViewBuilder
    func newNoteView() -> some View {
        VStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: { currentView = .viewList }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .padding([.trailing, .top], 3)
                }
                TextField("Select A Name",text: $newNoteName)
                    .padding(.horizontal, 10)

                Button(action: {
                    model.addNote(title: newNoteName)
                    addNewNoteOverlayIsPresented = false
                    newNoteName = ""
                    /// add new note to the list cuz it wont update
                }) {
                    Text("Add New Note")
                }
                Spacer()
            }
            .padding(.horizontal, 5)
        }
    }

        // ZStack {
        //     if addNewNoteOverlayIsPresented {
        //         /// Show a overlay to add a new note
        //     } else {
        //     }
        // }

    @ViewBuilder
    func renderFontControls() -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button(action: { currentFontSize = max(10, currentFontSize - 1) }) {
                Image(systemName: "minus.circle")
                    .foregroundColor(.white)
            }
            .frame(width: 20, height: 20)

            Button(action: { currentFontSize = min(30, currentFontSize + 1) }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.white)
            }
            .frame(width: 20, height: 20)
        }
        .cornerRadius(5)
        .background(Color.gray.opacity(0.7))
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    @ViewBuilder
    func renderTextEditor() -> some View {
        TextEditor(text: $model.text)
            .font(.system(size: currentFontSize))
            .foregroundColor(.white)
            .background(Color.black)
            .cornerRadius(8)
            .frame(height: 80)
            .onChange(of: model.text) {
                // model.saveNotes()
            }
    }

    @ViewBuilder
    func renderNotesSections() -> some View {
        ForEach(buttons, id: \.self) { button in
            Button(action: {
                model.selectedButton = button
                // model.loadNotes()  // Load the note for the selected button
            }) {
                Text(button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .foregroundColor(.white)
            }
            .background(button == model.selectedButton ? Color.blue : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    func renderFontToggle() -> some View {
        Button(action: {
            showFontControls.toggle()
        }) {
            Image(systemName: "textformat")
                .resizable()
                .frame(width: 10, height: 7)
                .foregroundColor(.white)
                .padding(.vertical, 2)
        }
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var content: String
}

class NotesWidgetModel: ObservableObject {
    /// New Logic for NotesWidget
    @Published var notes: [Note] = []
    @Published var selectedNoteID: UUID?

    private let storageKey = "notes_storage"

    @Published var text: String = ""
    @Published var selectedButton: String = "1"

    init() {
        loadNotes()  // Load initial note
    }

    func addNote(title: String) {
        let newNote = Note(id: UUID(), name: title, content: "")
        notes.append(newNote)
        selectedNoteID = newNote.id
        saveNotes()
    }

    func updateContent(for id: UUID, newContent: String) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].content = newContent
            saveNotes()
        }
    }

    func deleteNote(_ note: Note) {
       notes.removeAll { $0.id == note.id }
       saveNotes()
    }

    var selectedNote: Note? {
        get {
            notes.first { $0.id == selectedNoteID }
        }
    }

    private func loadNotes() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
            selectedNoteID = notes.first?.id
        }
    }

    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
