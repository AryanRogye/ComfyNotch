import AppKit
import Combine

class SettingsModel : ObservableObject {

    static let shared = SettingsModel()

    @Published var selectedWidgets: [String] = []
    @Published var isSettingsWindowOpen : Bool = false
    @Published var isCameraFlipped : Bool = false
    @Published var open_state_y_offset = CGFloat(35)
    @Published var snapOpenThreshold: CGFloat = 0.9
    @Published var ai_api_key: String = "" 

    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
    }

    /// Saves the current settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard

        print("Saving Widget Settings: \(selectedWidgets)") // Debug print

        // Saving the last state for whatever widgets are selected
        defaults.set(selectedWidgets, forKey: "selectedWidgets")


        defaults.set(isCameraFlipped, forKey: "isCameraFlipped")
        print("Saving camera flip state: \(isCameraFlipped)")

        /// For some reason the api key was getting called to save even if it was empty
        /// So I had to add this check, prolly gonna have to check that reason out <- TODO
        if !ai_api_key.isEmpty {
            defaults.set(ai_api_key, forKey: "ai_api_key")
        }
    }

    /// Updates `selectedWidgets` and triggers a reload notification immediately
    func updateSelectedWidgets(with widgetName: String, isSelected: Bool) {
        if isSelected {
            if !selectedWidgets.contains(widgetName) {
                selectedWidgets.append(widgetName)
                print("Added \(widgetName) to selectedWidgets: \(selectedWidgets)")
            }
        } else {
            if selectedWidgets.contains(widgetName) {
                selectedWidgets.removeAll { $0 == widgetName }
                print("Removed \(widgetName) from selectedWidgets: \(selectedWidgets)")
            } else {
                print("Attempted to remove \(widgetName), but it wasn't found in selectedWidgets: \(selectedWidgets)")
            }
        }
        
        saveSettings()
        print("NEW Saved Settings: \(selectedWidgets)")

        NotificationCenter.default.post(name: NSNotification.Name("ReloadWidgets"), object: nil)
    }


    /// Loads the last saved settings from UserDefaults
    func loadSettings() {
        let defaults = UserDefaults.standard

        // Loading the last state for the settings window
        if let loadedWidgets = defaults.object(forKey: "selectedWidgets") as? [String] {
            self.selectedWidgets = loadedWidgets
        } else {
            // Set default if nothing is saved
            self.selectedWidgets = WidgetRegistry.shared.getDefaultWidgets()
        }

        // Loading the last state for camera flip
        if defaults.object(forKey: "isCameraFlipped") != nil {
            self.isCameraFlipped = defaults.bool(forKey: "isCameraFlipped")
        }

        // Loading the last api_key the user entered
        if let apiKey = defaults.string(forKey: "ai_api_key") {
            self.ai_api_key = apiKey
        }
    }
}

class WidgetRegistry {
    static let shared = WidgetRegistry()

    private init() {}

    var widgets: [String: SwiftUIWidget] = [
        "MusicPlayerWidget": MusicPlayerWidget(),
        "TimeWidget": TimeWidget(),
        "NotesWidget": NotesWidget(),
        "CameraWidget": CameraWidget(),
        "AIChatWidget": AIChatWidget()
    ]

    func getWidget(named name: String) -> SwiftUIWidget? {
        return widgets[name]
    }

    func getDefaultWidgets() -> [String] {
        return ["MusicPlayerWidget", "TimeWidget", "NotesWidget"]
    }
}



enum AIProvider: String, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google"
}

enum OpenAIModel: String, CaseIterable {
    case gpt3 = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
}

enum AnthropicModel: String, CaseIterable {
    case claudeV1 = "claude-v1"
    case claudeV2 = "claude-v2"
}

enum GoogleModel: String, CaseIterable {
    case palm = "PaLM"
    case bard = "Bard"
}


class AIRegistery : ObservableObject {
    @Published var selectedProvider: AIProvider = .openAI
    @Published var selectedOpenAIModel: OpenAIModel = .gpt3
    @Published var selectedAnthropicModel: AnthropicModel = .claudeV1
    @Published var selectedGoogleModel: GoogleModel = .palm
}
