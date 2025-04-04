import SwiftUI
import Combine

class SettingsModel: ObservableObject {
    static let shared = SettingsModel() // Singleton for global access

    @Published var open_state_y_offset: CGFloat = 35
    @Published var isSettingsOpen: Bool = false

    @Published var ai_api_key : String = "" {
        didSet {
            NotificationCenter.default.post(name: .init("AIKeyChanged"), object: nil)
            saveSettings()
        }
    }

    @Published var selectedProvider: AIProvider = .openAI
    @Published var selectedOpenAIModel: OpenAIModel = .gpt3
    @Published var selectedAnthropicModel: AnthropicModel = .claudeV1
    @Published var selectedGoogleModel: GoogleModel = .palm

    @Published var mappedWidgets: [String: Widget] = [
        "MusicPlayerWidget": MusicPlayerWidget(),
        "TimeWidget": TimeWidget(),
        "NotesWidget": NotesWidget(),
        "CameraWidget": CameraWidget(),
        "AIChatWidget": AIChatWidget(),
    ]

    @Published var selectedWidgets: [String] = [] // This will be loaded from UserDefaults

    private var cancellables = Set<AnyCancellable>()

    @Published var flipCamera: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .init("FlipCameraChanged"), object: nil)
            saveSettings()
        }
    }

    init() {
        loadSettings()  // Load saved settings from UserDefaults

        $selectedWidgets
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { widgets in
                NotificationCenter.default.post(name: NSNotification.Name("ReloadWidgets"), object: nil)
                self.saveSettings() // Save whenever widgets change

                if !widgets.contains("CameraWidget") || UIManager.shared.panel_state == .CLOSED {
                    (self.mappedWidgets["CameraWidget"] as? CameraWidget)?.hide()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Save settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(selectedWidgets, forKey: "selectedWidgets")
        defaults.set(flipCamera, forKey: "flipCamera")
        if !ai_api_key.isEmpty {
            print("Saving API Key: \(ai_api_key)")  // Debugging
            defaults.set(ai_api_key, forKey: "ai_api_key")
        } else {
            print("API Key is empty. Not saving.")  // Debugging
        }
    }

    /// Load settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load selected widgets
        if let loadedWidgets = defaults.object(forKey: "selectedWidgets") as? [String] {
            self.selectedWidgets = loadedWidgets
        } else {
            // Set default if nothing is saved
            self.selectedWidgets = ["MusicPlayerWidget", "TimeWidget", "NotesWidget"]
        }
        
        // Load flip camera setting
        if defaults.object(forKey: "flipCamera") != nil {
            self.flipCamera = defaults.bool(forKey: "flipCamera")
        }

        // Load AI API key
        if let apiKey = defaults.string(forKey: "ai_api_key") {
            print("Loaded API Key: \(apiKey)")  // Add this for debugging
            self.ai_api_key = apiKey
        } else {
            print("No API key found in UserDefaults") // Add this for debugging
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared

    @State private var selectedTab = 0

    var body: some View {
        HStack {
            TabView(selection: $selectedTab) {
                MainSettingsView(settings: settings)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(0)
                AISettingsView(settings: settings)
                    .tabItem {
                        Image(systemName: "brain")
                        Text("AI Settings")
                    }
                    .tag(1)
            }
        }.onDisappear {
            settings.isSettingsOpen = false
        }
    }    
}

struct DropViewDelegate: DropDelegate {
    var item: String
    var settings: SettingsModel
    @Binding var draggingItem: String?
    @Binding var isDragging: Bool

    func performDrop(info: DropInfo) -> Bool {
        guard let draggingItem = draggingItem else { return false }
        
        if let fromIndex = settings.selectedWidgets.firstIndex(of: draggingItem),
           let toIndex = settings.selectedWidgets.firstIndex(of: item),
           fromIndex != toIndex {
            
            withAnimation {
                let movedItem = settings.selectedWidgets.remove(at: fromIndex)
                settings.selectedWidgets.insert(movedItem, at: toIndex)
            }
            self.draggingItem = nil
            self.isDragging = false
            return true
        }
        return false
    }
}