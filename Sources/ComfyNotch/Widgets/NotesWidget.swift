import AppKit
import SwiftUI


struct NotesWidget : View, Widget {

    var name: String = "NotesWidget"
    private var buttons: [String] = ["1", "2", "3"]

    @ObservedObject var model = NotesWidgetModel()  // Using your model
    @State var currentFontSize : CGFloat = 14
    @State var showFontControls : Bool = false

    var body: some View {
        ZStack {
            HStack(spacing: 3) {
                VStack(spacing: 0) {
                    renderNotesSections()
                    renderFontToggle()
                }
                .background(Color.clear)
                .padding(.leading, 3)
                .frame(maxWidth: 30)

                renderTextEditor()
            }
            if showFontControls {
                renderFontControls()
            }
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 3)
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
            .onChange(of: model.text) { _ in
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