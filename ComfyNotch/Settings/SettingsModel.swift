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

    @Published var clipboardManagerMaxHistory: Int = 10
    @Published var clipboardManagerPollingIntervalMS: Int = 1000
    
    @Published var fileTrayDefaultFolder: URL = FileManager.default
                                                    .urls(for: .documentDirectory, in: .userDomainMask)
                                                    .first!
                                                    .appendingPathComponent("ComfyNotch Files", isDirectory: true)
    @Published var fileTrayPersistFiles : Bool = false
    @Published var useCustomSaveFolder : Bool = false
    @Published var showDividerBetweenWidgets: Bool = false /// False cuz i like it without
    
    @Published var nowPlayingScrollSpeed: Int = 40
    @Published var enableNotchHUD: Bool = true

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadSettings()
    }

    /// Saves the current settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard

        // Saving the last state for whatever widgets are selected
        defaults.set(selectedWidgets, forKey: "selectedWidgets")

        defaults.set(isCameraFlipped, forKey: "isCameraFlipped")
        
        /// For some reason the api key was getting called to save even if it was empty
        /// So I had to add this check, prolly gonna have to check that reason out <- TODO
        if !aiApiKey.isEmpty {
            defaults.set(aiApiKey, forKey: "aiApiKey")
        }
        
        /// ----------------------- FileTray Settings ------------------------------------
        /// Save the fileTrayFolder
        /// Set Default for the file tray folder if nothing is found
        fileTrayDefaultFolder = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("ComfyNotch Files", isDirectory: true)
        /// if we reach here, that means that the fileTray is populated no matter what so we can force it to get stored
        if !fileTrayDefaultFolder.path.isEmpty {
            defaults.set(fileTrayDefaultFolder.path(), forKey: "fileTrayDefaultFolder")
        }
        defaults.set(fileTrayPersistFiles, forKey: "fileTrayPersistFiles")
        
        /// ----------------------- ClipBoard Settings -----------------------------------
        if clipboardManagerMaxHistory >= 0 {
            defaults.set(clipboardManagerMaxHistory, forKey: "clipboardManagerMaxHistory")
        }
        if clipboardManagerPollingIntervalMS >= 0 {
            defaults.set(clipboardManagerPollingIntervalMS, forKey: "clipboardManagerPollingIntervalMS")
        }
        /// ----------------------- Divider Settings -------------------------------------
        defaults.set(showDividerBetweenWidgets, forKey: "showDividerBetweenWidgets")
        
        /// ----------------------- Notch Settings -------------------------------------
        if nowPlayingScrollSpeed > 0 {
            defaults.set(nowPlayingScrollSpeed, forKey: "nowPlayingScrollSpeed")
        } else {
            defaults.set(40, forKey: "nowPlayingScrollSpeed")
        }
        defaults.set(enableNotchHUD, forKey: "enableNotchHUD")
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
        
        /// ----------------------- FileTray Settings ------------------------------------
        if let fileTrayDefaultFolder = defaults.string(forKey: "fileTrayDefaultFolder") {
            self.fileTrayDefaultFolder = URL(fileURLWithPath: fileTrayDefaultFolder)
        }
        if let fileTrayPersistFiles = defaults.object(forKey: "fileTrayPersistFiles") as? Bool {
            self.fileTrayPersistFiles = fileTrayPersistFiles
        }

        /// ----------------------- ClipBoard Settings -----------------------------------
        if let clipboardManagerMaxHistory = defaults.object(forKey: "clipboardManagerMaxHistory") as? Int {
            self.clipboardManagerMaxHistory = clipboardManagerMaxHistory
        }
        /// Load in the clipboardManagerPollingIntervalMS
        if let clipboardManagerPollingIntervalMS = defaults.object(forKey: "clipboardManagerPollingIntervalMS") as? Int {
            self.clipboardManagerPollingIntervalMS = clipboardManagerPollingIntervalMS
        }
        if let showDividerBetweenWidgets = defaults.object(forKey: "showDividerBetweenWidgets") as? Bool {
            self.showDividerBetweenWidgets = showDividerBetweenWidgets
        }
        
        /// ----------------------- Notch Scroll Settings -----------------------
        if let nowPlayingScrollSpeed = defaults.object(forKey: "nowPlayingScrollSpeed") as? Int {
            self.nowPlayingScrollSpeed = nowPlayingScrollSpeed
        } else {
            self.nowPlayingScrollSpeed = 40
        }
        if let enableNotchHUD = defaults.object(forKey: "enableNotchHUD") as? Bool {
            self.enableNotchHUD = enableNotchHUD
        } else {
            self.enableNotchHUD = true
        }
    }

    /// Updates `selectedWidgets` and triggers a reload notification immediately
    func updateSelectedWidgets(with widgetName: String, isSelected: Bool) {

        debugLog("Updating selected widgets with: \(widgetName), isSelected: \(isSelected)")

        // Starting With Remove Logic so we can clear out any old widgets

        if !isSelected {
            if selectedWidgets.contains(widgetName) {
                selectedWidgets.removeAll { $0 == widgetName }
                UIManager.shared.expandedWidgetStore.removeWidget(named: widgetName)
                debugLog("Removed widget: \(widgetName)")
            } else {
                debugLog("Widget \(widgetName) not found in selected widgets")
                exit(0)
            }
        }

        // Add Logic
        if isSelected {
            if !selectedWidgets.contains(widgetName) {
                selectedWidgets.append(widgetName)
                if let widget = WidgetRegistry.shared.getWidget(named: widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                    debugLog("Added widget: \(widgetName)")
                }
            }
        }

        saveSettings()
        debugLog("NEW Saved Settings: \(selectedWidgets)")

        // Refresh the UI only if the panel is open
        if UIManager.shared.panelState == .open {
            refreshUI()
        } else {
            debugLog("Panel is not open, not refreshing UI")
        }
    }

    func refreshUI() {
        if UIManager.shared.panelState == .open {
            AudioManager.shared.startMediaTimer()
            UIManager.shared.smallPanel.contentView?.needsLayout = true
            UIManager.shared.smallPanel.contentView?.layoutSubtreeIfNeeded()

            DispatchQueue.main.async {
                UIManager.shared.smallPanel.contentView?.needsDisplay = true
                UIManager.shared.applyExpandedWidgetLayout()
            }
        }
    }

    func removeAndAddBackCurrentWidgets() {
        debugLog("🔄 Rebuilding widgets in the panel based on the updated order.")

        // Clear all currently displayed widgets
        UIManager.shared.expandedWidgetStore.clearWidgets()

        // Iterate over the updated selectedWidgets list
        for widgetName in selectedWidgets {
            if let widget = WidgetRegistry.shared.getWidget(named: widgetName) {
                UIManager.shared.addWidgetToBigPanel(widget)
            } else {
                debugLog("⚠️ Widget \(widgetName) not found in WidgetRegistry.")
            }
        }

        // Finally, refresh the UI
        refreshUI()
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
        "AIChatWidget": AIChatWidget(),
        "EventWidget": EventWidget()
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
