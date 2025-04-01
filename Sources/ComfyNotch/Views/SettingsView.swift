import SwiftUI
import Combine

class SettingsModel: ObservableObject {
    static let shared = SettingsModel() // Singleton for global access

    @Published var mappedWidgets: [String: Widget] = [
        "MusicPlayerWidget": MusicPlayerWidget(),
        "TimeWidget": TimeWidget(),
        "NotesWidget": NotesWidget()
    ]
    
    @Published var selectedWidgets: [String] = ["MusicPlayerWidget", "TimeWidget"] // Default selected widgets

    private var cancellables = Set<AnyCancellable>()

    init() {
    $selectedWidgets
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main) // Give it some time before triggering the reload
            .sink { _ in
                NotificationCenter.default.post(name: NSNotification.Name("ReloadWidgets"), object: nil)
            }
            .store(in: &cancellables)
    }
}
struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding()

            Text("Adjust your settings here.")
                .padding()

            ForEach(Array(settings.mappedWidgets.keys), id: \.self) { widgetName in
                Toggle(isOn: Binding(
                    get: { settings.selectedWidgets.contains(widgetName) },
                    set: { isSelected in
                        if isSelected {
                            settings.selectedWidgets.append(widgetName)
                        } else {
                            settings.selectedWidgets.removeAll { $0 == widgetName }
                        }
                    }
                )) {
                    Text(widgetName)
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                closeWindow()
            }) {
                Text("Exit From ComfyNotch")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: closeWindow) {
                Text("Close ComfyNotch")
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    func closeWindow() {
        NSApplication.shared.keyWindow?.close()
        NSApp.terminate(nil)
    }
}