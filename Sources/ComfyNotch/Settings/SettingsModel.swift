import AppKit
import Combine

class SettingsModel: ObservableObject {

    static let shared = SettingsModel()

    @Published var selectedWidgets: [String] = []
    @Published var isSettingsWindowOpen: Bool = false
    @Published var isCameraFlipped: Bool = false
    @Published var openStateYOffset = CGFloat(35)
    @Published var snapOpenThreshold: CGFloat = 0.9
    @Published var aiApiKey: String = ""
    
    @Published var selectedProvider: AIProvider = .openAI
    @Published var selectedOpenAIModel: OpenAIModel = .gpt3
    @Published var selectedAnthropicModel: AnthropicModel = .claudeV1
    @Published var selectedGoogleModel: GoogleModel = .palm

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
        if !aiApiKey.isEmpty {
            defaults.set(aiApiKey, forKey: "aiApiKey")
        }
    }

    /// Updates `selectedWidgets` and triggers a reload notification immediately
    func updateSelectedWidgets(with widgetName: String, isSelected: Bool) {

        print("Updating selected widgets with: \(widgetName), isSelected: \(isSelected)")

        // Starting With Remove Logic so we can clear out any old widgets

        if !isSelected {
            if selectedWidgets.contains(widgetName) {
                selectedWidgets.removeAll { $0 == widgetName }
                UIManager.shared.bigWidgetStore.removeWidget(named: widgetName)
                print("Removed widget: \(widgetName)")
            } else {
                print("Widget \(widgetName) not found in selected widgets")
                exit(0)
            }
        }

        // Add Logic
        if isSelected {
            if !selectedWidgets.contains(widgetName) {
                selectedWidgets.append(widgetName)
                if let widget = WidgetRegistry.shared.getWidget(named: widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                    print("Added widget: \(widgetName)")
                }
            }
        }

        saveSettings()
        print("NEW Saved Settings: \(selectedWidgets)")

        // Refresh the UI only if the panel is open
        if UIManager.shared.panelState == .open {
            refreshUI()
        } else {
            print("Panel is not open, not refreshing UI")
        }
    }

    func refreshUI() {
        if UIManager.shared.panelState == .open {
            AudioManager.shared.startMediaTimer()
            UIManager.shared.bigPanel.contentView?.needsLayout = true
            UIManager.shared.bigPanel.contentView?.layoutSubtreeIfNeeded()

            DispatchQueue.main.async {
                UIManager.shared.bigPanel.contentView?.needsDisplay = true
                UIManager.shared.showBigPanelWidgets()
            }
        }
    }

    func removeAndAddBackCurrentWidgets() {
        print("🔄 Rebuilding widgets in the panel based on the updated order.")

        // Clear all currently displayed widgets
        UIManager.shared.bigWidgetStore.clearWidgets()

        // Iterate over the updated selectedWidgets list
        for widgetName in selectedWidgets {
            if let widget = WidgetRegistry.shared.getWidget(named: widgetName) {
                UIManager.shared.addWidgetToBigPanel(widget)
            } else {
                print("⚠️ Widget \(widgetName) not found in WidgetRegistry.")
            }
        }

        // Finally, refresh the UI
        refreshUI()
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
        if let apiKey = defaults.string(forKey: "aiApiKey") {
            self.aiApiKey = apiKey
        }
    }
}

class WidgetRegistry {
    static let shared = WidgetRegistry()

    private init() {}

    var widgets: [String: Widget] = [
        "MusicPlayerWidget": MusicPlayerWidget(),
        "TimeWidget": TimeWidget(),
        "NotesWidget": NotesWidget(),
        "CameraWidget": CameraWidget(),
        "AIChatWidget": AIChatWidget()
    ]

    func getWidget(named name: String) -> Widget? {
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

class AIRegistery: ObservableObject {
    @Published var selectedProvider: AIProvider = .openAI
    @Published var selectedOpenAIModel: OpenAIModel = .gpt3
    @Published var selectedAnthropicModel: AnthropicModel = .claudeV1
    @Published var selectedGoogleModel: GoogleModel = .palm
}
