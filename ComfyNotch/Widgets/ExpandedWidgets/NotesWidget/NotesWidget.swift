import AppKit
import SwiftUI

enum NotesWidgetViewState: Equatable {
    case viewList
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
    
    @State private var currentView: NotesWidgetViewState = .viewList
    @ObservedObject private var hoverState = WidgetHoverState.shared
    
    @State private var addNewNoteTriggered: Bool = false
    @State private var deletingNote: Note? = nil
    @State private var deleteNoteTriggered: Bool = false
    
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    var body: some View {
        VStack {
            ZStack {
                
                if addNewNoteOverlayIsPresented {
                    NewNotesView(
                        addNewNoteOverlayIsPresented: $addNewNoteOverlayIsPresented)
                } else if deleteNoteTriggered {
                    DeleteNoteView(
                        deleteNoteTriggered: $deleteNoteTriggered,
                        deletingNote: $deletingNote
                    )
                } else {
                    switch currentView {
                    case .viewList:
                        HomeNotesView(
                            addNewNoteOverlayIsPrented: $addNewNoteOverlayIsPresented,
                            currentView: $currentView,
                            deletingNote: $deletingNote,
                            deleteNoteTriggered: $deleteNoteTriggered
                        )
                    case .editor(let note):
                        NotesEditorView(
                            note: note, currentView: $currentView
                        )
                        //                        showEditorView(note: note)
                    }
                }
                
            }
            .environmentObject(model)
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
        .onAppear {
            givenSpace = GivenWidgetSpace(w: 0, h: 0)
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }
        .onChange(of: [givenSpace.w, givenSpace.h]) { _, newValue in
            print("w: \(newValue[0]), h: \(newValue[1])")
        }
        
        .onHover { hovering in
            hoverState.isHovering = hovering
        }
    }
    
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
    @Published var text: String = ""
    
    private let storageKey = "notes_storage"
    
    @Published var selectedButton: String = "1"
    
    public let currentFontSize: CGFloat = 14
    
    private var userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadNotes()
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
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
            selectedNoteID = notes.first?.id
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}
