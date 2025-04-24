import AppKit
import SwiftUI

struct NotesWidget: View, Widget {

    var name: String = "NotesWidget"
    private var buttons: [String] = ["1", "2", "3"]

    @ObservedObject var model = NotesWidgetModel()  // Using your model
    @State var currentFontSize: CGFloat = 14
    @State var showFontControls: Bool = false
    
    @State private var addNewNoteOverlayIsPresented: Bool = false
    @State private var newNoteName: String = ""

    var body: some View {
        ZStack {
            if addNewNoteOverlayIsPresented {
                /// Show a overlay to add a new note
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { addNewNoteOverlayIsPresented = false } ) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                        .padding([.trailing, .top], 3)
                    }
                    TextField("Select A Name",text: $newNoteName)
                        .padding(.horizontal, 10)
                    
                    Button(action: {} ) {
                        Text("Add New Note")
                    }
                    Spacer()
                }
                .padding(.horizontal, 5)
            } else {
                VStack {
                    HStack {
                        /// We wanna cool search bar here
                        Spacer()
                        Button(action: { addNewNoteOverlayIsPresented = true } ) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                        .padding([.trailing, .top], 3)
                    }
                    /// Default 3 notes
                    ScrollView(.vertical, showsIndicators: true) {
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                        Text("Hello")
                    }
                }
                //            HStack(spacing: 3) {
                //                VStack(spacing: 0) {
                //                    renderNotesSections()
                //                    renderFontToggle()
                //                }
                //                .background(Color.clear)
                //                .frame(maxWidth: 20)
                //
                //                renderTextEditor()
                //            }
                //            if showFontControls {
                //                renderFontControls()
                //            }
            }
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(Color.white, width: 1)
            
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
                model.saveNotes()
            }
    }

    @ViewBuilder
    func renderNotesSections() -> some View {
        ForEach(buttons, id: \.self) { button in
            Button(action: {
                model.selectedButton = button
                model.loadNotes()  // Load the note for the selected button
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

class NotesWidgetModel: ObservableObject {
    @Published var text: String = ""
    @Published var selectedButton: String = "1"

    init() {
        loadNotes()  // Load initial note
    }

    func loadNotes() {
        let key = "\(selectedButton)_content"
        let defaultText = "Hello, this is a test note.\nYou can edit this text."
        let savedText = UserDefaults.standard.string(forKey: key) ?? defaultText
        text = savedText
    }

    func saveNotes() {
        UserDefaults.standard.set(text, forKey: "\(selectedButton)_content")
    }
}
