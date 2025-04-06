import AppKit
import SwiftUI


struct NotesWidget : View, SwiftUIWidget {

    var name: String = "NotesWidget"
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