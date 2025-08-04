import AppKit
import Combine
import Sparkle
import AVKit
import SwiftUI

class SettingsModel: ObservableObject {
    static let shared = SettingsModel(userDefaults: .standard)
    
    @Published var selectedTab: SettingsView.Tab = .general
    @Published var selectedNotchTab: Int = 0
    
    @Published var isFirstLaunch: Bool = true
    @Published var hasFirstWindowBeenOpenOnce = false
    
    @Published var selectedWidgets: [String] = []
    @Published var isSettingsWindowOpen: Bool = false
    @Published var openStateYOffset = CGFloat(35)
    @Published var snapOpenThreshold: CGFloat = 0.9
    
    @Published var clipboardManagerMaxHistory: Int = 30
    @Published var clipboardManagerPollingIntervalMS: Int = 1000
    
    @Published var fileTrayDefaultFolder: URL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("ComfyNotch Files", isDirectory: true)
    
    /// ----------- FileTray Settings ----------
    @Published var useCustomSaveFolder : Bool = false
    
    /// qr options
    @Published var fileTrayAllowOpenOnLocalhost: Bool = false
    @Published var fileTrayPort: Int = 8000
    @Published var localHostPin: String = "1111"
    
    /// ----------- Notch Settings -----------
    @Published var showDividerBetweenWidgets: Bool = false
    @Published var hoverTargetMode: HoverTarget = .none
    @Published var enableButtonsOnHover: Bool = false
    @Published var enableNotchHUD: Bool = false
    
    /// Controlling the width of the notch, My Refular Used to be 700 but changed to 450
    /// cuz lots of users suggested that it was too wide, looked like a iPhone
    @Published var notchMaxWidth: CGFloat = 450
    
    // WARNING: Should NOT BE UNDER 320
    let MIN_NOTCH_MAX_WIDTH : CGFloat = 270
    let MAX_NOTCH_MAX_WIDTH : CGFloat = 1000
    
    @Published var notchMinWidth: CGFloat = 270
    
    let MIN_NOTCH_MIN_WIDTH : CGFloat = 270
    let MAX_NOTCH_MIN_WIDTH : CGFloat = 2000
    
    // NOTE: this is is very important because this will be what
    // the notch will be set to when it is closed, if this is
    // <= 0 this is a BIG ISSUE
    // this is cuz in `Managers/UIManager.swift` we use this:
    //
    // let notchHeight = getNotchHeight()
    //
    // let panelRect = NSRect(
    // x: (screenFrame.width - startPanelWidth) / 2,
    // y: screenFrame.height - notchHeight - startPanelYOffset,
    // width: startPanelWidth,
    // height: notchHeight
    // )
    @Published var notchMinFallbackHeight: CGFloat = 40
    /// Min and Max Values for the fallback Height
    let notchHeightMin : Int = 35
    let notchHeightMax : Int = 50
    
    /// Function to reset the min fallback height to the default value
    public func resetNotchMinFallbackHeight() {
        notchMinFallbackHeight = 40
    }
    
    @Published var quickAccessWidgetDistanceFromLeft: CGFloat = 18
    @Published var quickAccessWidgetDistanceFromTop: CGFloat = 4
    @Published var settingsWidgetDistanceFromRight: CGFloat = 18
    @Published var oneFingerAction: TouchAction = .none
    @Published var twoFingerAction: TouchAction = .none
    @Published var notchScrollThreshold: CGFloat = 50
    
    // MARK: - Music Setting Values
    /// ---------- Music Player Settings ----------
    @Published var musicPlayerStyle : MusicPlayerWidgetStyle = .comfy
    @Published var showMusicProvider: Bool = true
    @Published var musicController: MusicController = .mediaRemote
    @Published var overridenMusicProvider: MusicProvider = .none
    @Published var enableAlbumFlippingAnimation: Bool = true

    // MARK: - Camera Setting Values
    /// ---------- Camera Settings ----------
    @Published var isCameraFlipped: Bool = false
    /// Suggest Users to enable this for better memory management
    @Published var enableCameraOverlay: Bool = true
    /// This is the amount of time before the camera
    /// overlay hides itself, default will be 20 seconds
    @Published var cameraOverlayTimer: Int = 20
    @Published var cameraQualitySelection: AVCaptureSession.Preset = .high
    
    // MARK: - Event Widget Values
    /// ---------- Event Widget Settings ----------
    let DEFAULT_EVENT_WIDGET_SCROLL_UP_THRESHOLD : CGFloat = 3000.0
    let MIN_EVENT_WIDGET_SCROLL_UP_THRESHOLD     : CGFloat = 1000.0
    let MAX_EVENT_WIDGET_SCROLL_UP_THRESHOLD     : CGFloat = 5000.0
    @Published var eventWidgetScrollUpThreshold  : CGFloat = 3000.0

    
    /// ---------- Display Settings ----------
    @Published var selectedScreen: NSScreen! = NSScreen.main!
    /// ---------- Animation Settings ----------
    @Published var openingAnimation: String = "iOS"
    @Published var notchBackgroundAnimation: ShaderOption = .ambientGradient
    @Published var enableMetalAnimation: Bool = true
    @Published var constant120FPS: Bool = false
    
    /// ---------- Messages Settings ----------
    /// This is required to be false on start cuz theres no way
    /// to prompt or make the user silence "Messages" Notifications,
    /// Maybe we can add a prompt later on to ask the user or just
    /// force it down
    @Published var enableMessagesNotifications: Bool = false
    @Published var messagesHandleLimit: Int = 30
    @Published var messagesMessageLimit: Int = 20
    @Published var currentMessageAudioFile: String = ""
    
    /// ---------- Utils Settings ----------
    /// Set to false at the start, will change if the user wants to enable or disable this feature.
    /// The thing is that if the user turns this off we have to verify that the
    /// clipboard are off, or else just dont
    /// let the user turn it off
    @Published var enableUtilsOption: Bool = false
    @Published var enableClipboardListener: Bool = false
    
    /// ---------- Quick Access Widget Settings ----------
    @Published var quickAccessWidgetSimpleDynamic: QuickAccessType = .dynamic
    
    
    /// REQUIRED FOR UPDATING
    lazy var updaterController: SPUStandardUpdaterController = {
        return SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }()
    
    private var cancellables = Set<AnyCancellable>()
    private let defaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        loadSettings()
        
        #if DEBUG
        handleLaunchArgs()
        #endif
        
        $isSettingsWindowOpen
            .receive(on: RunLoop.main)
            .sink { isOpen in
                if isOpen {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
#if DEBUG
    private func handleLaunchArgs() {
        let args = ProcessInfo.processInfo.arguments
        
        if let index = args.firstIndex(of: "--uitest-selectedTab"),
           args.count > index + 1 {
            
            let tabValue = args[index + 1]
            switch tabValue {
            case "widgetSettings"   : self.selectedTab = .widgetSettings
            case "general"          : self.selectedTab = .general
            default                 : break
            }
        }
        
        if let index = args.firstIndex(of: "--uitest-hover"),
           args.count > index + 1 {
            
            let value = args[index + 1]
            switch value {
            case "on"  : self.hoverTargetMode = .album
            case "off" : self.hoverTargetMode = .none
            default: break
            }
        }
    }
#endif
    
    // MARK: - Updates
    
    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
    
    func checkForUpdatesSilently() {
        updaterController.updater.checkForUpdatesInBackground()
    }
    
    // MARK: - Load Settings
    /// Loads the last saved settings from UserDefaults
    func loadSettings() {
        // Load fallback notch height with validation
        if let notchMinFallbackHeight = defaults.object(forKey: "notchMinFallbackHeight") as? Double {
            self.notchMinFallbackHeight = CGFloat(notchMinFallbackHeight > 0 ? notchMinFallbackHeight : 40)
        } else {
            self.notchMinFallbackHeight = CGFloat(40)
        }
        
        // Loading the last state for the settings window
        if let loadedWidgets = defaults.object(forKey: "selectedWidgets") as? [String] {
            self.selectedWidgets = loadedWidgets
        } else {
            // Set default if nothing is saved
            self.selectedWidgets = WidgetRegistry.shared.getDefaultWidgets()
        }
        
        /// ----------------------- Camera Settings -----------------------
        // Loading the last state for camera flip
        if defaults.object(forKey: "isCameraFlipped") != nil {
            self.isCameraFlipped = defaults.bool(forKey: "isCameraFlipped")
        }
        if defaults.object(forKey: "enableCameraOverlay") != nil {
            self.enableCameraOverlay = defaults.bool(forKey: "enableCameraOverlay")
        }
        if let cameraOverlayTimer = defaults.object(forKey: "cameraOverlayTimer") as? Int {
            self.cameraOverlayTimer = cameraOverlayTimer
        } else {
            // Set default if nothing is saved
            self.cameraOverlayTimer = 20
        }
        
        /// ----------------------- FileTray Settings ------------------------------------
        if let fileTrayDefaultFolder = defaults.string(forKey: "fileTrayDefaultFolder") {
            self.fileTrayDefaultFolder = URL(fileURLWithPath: fileTrayDefaultFolder)
        }
        
        if let fileTrayAllowOpenOnLocalhost = defaults.object(forKey: "fileTrayAllowOpenOnLocalhost") as? Bool {
            self.fileTrayAllowOpenOnLocalhost = fileTrayAllowOpenOnLocalhost
        } else {
            self.fileTrayAllowOpenOnLocalhost = false
        }
        
        if let fileTrayPort = defaults.object(forKey: "fileTrayPort") as? Int {
            self.fileTrayPort = fileTrayPort
        } else {
            self.fileTrayPort = 8000 // Default port
        }
        
        if let localHostPin = defaults.string(forKey: "localHostPin") {
            self.localHostPin = localHostPin
        } else {
            self.localHostPin = "1111" // Default pin
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
        
        /// ----------------------- Hover Settings -----------------------------------
        if let hoverTarget = defaults.object(forKey: "hoverTargetMode") as? String {
            self.hoverTargetMode = HoverTarget(rawValue: hoverTarget) ?? .album
        } else {
            self.hoverTargetMode = .none /// default to none
        }
        if let enableButtonsOnHover = defaults.object(forKey: "enableButtonsOnHover") as? Bool {
            self.enableButtonsOnHover = enableButtonsOnHover
        } else {
            self.enableButtonsOnHover = false
        }

        if let enableNotchHUD = defaults.object(forKey: "enableNotchHUD") as? Bool {
            self.enableNotchHUD = enableNotchHUD
        } else {
            self.enableNotchHUD = false
        }
        
        if let notchMaxWidth = defaults.object(forKey: "notchMaxWidth") as? CGFloat {
            self.notchMaxWidth = notchMaxWidth
        } else {
            self.notchMaxWidth = 450
        }
        
        if let notchMinWidth = defaults.object(forKey: "notchMinWidth") as? CGFloat {
            self.notchMinWidth = notchMinWidth
        } else {
            self.notchMinWidth = 290
        }
        
        /// quickAccessWidgetDistanceFromLeft Loading Logic
        if let quickAccessWidgetDistanceFromLeft = defaults.object(forKey: "quickAccessWidgetDistanceFromLeft") as? CGFloat {
            self.quickAccessWidgetDistanceFromLeft = quickAccessWidgetDistanceFromLeft
        } else {
            self.quickAccessWidgetDistanceFromLeft = 18
        }
        
        if let quickAccessWidgetDistanceFromTop = defaults.object(forKey: "quickAccessWidgetDistanceFromTop") as? CGFloat {
            self.quickAccessWidgetDistanceFromTop = quickAccessWidgetDistanceFromTop
        } else {
            self.quickAccessWidgetDistanceFromTop = 4
        }
        
        if let settingsWidgetDistanceFromRight = defaults.object(forKey: "settingsWidgetDistanceFromRight") as? CGFloat {
            self.settingsWidgetDistanceFromRight = settingsWidgetDistanceFromRight
        } else {
            self.settingsWidgetDistanceFromRight = 18
        }
        
        if let oneFingerActionRawValue = defaults.string(forKey: "oneFingerAction"),
           let oneFingerAction = TouchAction(rawValue: oneFingerActionRawValue) {
            self.oneFingerAction = oneFingerAction
        } else {
            self.oneFingerAction = .none
        }
        
        if let twoFingerActionRawValue = defaults.string(forKey: "twoFingerAction"),
           let twoFingerAction = TouchAction(rawValue: twoFingerActionRawValue) {
            self.twoFingerAction = twoFingerAction
        } else {
            self.twoFingerAction = .none
        }
        
        if let notchScrollThreshold = defaults.object(forKey: "notchScrollThreshold") as? CGFloat {
            self.notchScrollThreshold = notchScrollThreshold
        } else {
            self.notchScrollThreshold = 50 // Default threshold
        }
        
        /// ----------------------- Music Player Settings -----------------------
        if let showMusicProvider = defaults.object(forKey: "showMusicProvider") as? Bool {
            self.showMusicProvider = showMusicProvider
        } else {
            self.showMusicProvider = true
        }
        
        if let musicControllerRawValue = defaults.string(forKey: "musicController"),
           let musicController = MusicController(rawValue: musicControllerRawValue) {
            self.musicController = musicController
        } else {
            self.musicController = .mediaRemote
        }
        
        if let overridenMusicProviderRawValue = defaults.string(forKey: "overridenMusicProvider"),
           let overridenMusicProvider = MusicProvider(rawValue: overridenMusicProviderRawValue) {
            self.overridenMusicProvider = overridenMusicProvider
        } else {
            self.overridenMusicProvider = .none
        }
        
        if let musicPlayerStyleRawValue = defaults.string(forKey: "musicPlayerStyle"),
           let musicPlayerStyle = MusicPlayerWidgetStyle(rawValue: musicPlayerStyleRawValue) {
            self.musicPlayerStyle = musicPlayerStyle
        } else {
            self.musicPlayerStyle = .comfy
        }
        if let enableAlbumFlippingAnimation = defaults.object(forKey: "enableAlbumFlippingAnimation") as? Bool {
            self.enableAlbumFlippingAnimation = enableAlbumFlippingAnimation
        } else {
            self.enableAlbumFlippingAnimation = true
        }

        /// ----------------------- Event Widget Settings -----------------------
        if let eventWidgetScrollUpThreshold = defaults.object(forKey: "eventWidgetScrollUpThreshold") as? CGFloat {
            self.eventWidgetScrollUpThreshold = eventWidgetScrollUpThreshold
        } else {
            self.eventWidgetScrollUpThreshold = DEFAULT_EVENT_WIDGET_SCROLL_UP_THRESHOLD
        }
        
        /// ----------------------- Messages Settings -----------------------
        if let enableMessagesNotifications = defaults.object(forKey: "enableMessagesNotifications") as? Bool {
            self.enableMessagesNotifications = enableMessagesNotifications
        } else {
            self.enableMessagesNotifications = false
        }
        
        if let messagesHandleLimit = defaults.object(forKey: "messagesHandleLimit") as? Int {
            self.messagesHandleLimit = messagesHandleLimit
        } else {
            self.messagesHandleLimit = 30
        }
        
        if let messagesMessageLimit = defaults.object(forKey: "messagesMessageLimit") as? Int {
            self.messagesMessageLimit = messagesMessageLimit
        } else {
            self.messagesMessageLimit = 20
        }
        
        /// ----------------------- Display Settings -----------------------
        if let screen = defaults.object(forKey: "selectedScreenID") as? CGDirectDisplayID {
            self.selectedScreen = NSScreen.screens.first(where: { $0.displayID == screen }) ?? NSScreen.main
        } else {
            self.selectedScreen = NSScreen.main
        }
        
        /// ----------------------- Animation Settings -----------------------
        if let openingAnimation = defaults.string(forKey: "openingAnimation") {
            self.openingAnimation = openingAnimation
        } else {
            self.openingAnimation = "iOS" // Default animation
        }
        
        if let name = defaults.string(forKey: "notchBackgroundAnimation"),
           let option = ShaderOption(rawValue: name) {
            self.notchBackgroundAnimation = option
        } else {
            self.notchBackgroundAnimation = .ambientGradient
        }
        
        if let enableMetalAnimation = defaults.object(forKey: "enableMetalAnimation") as? Bool {
            self.enableMetalAnimation = enableMetalAnimation
        } else {
            self.enableMetalAnimation = true // Default to true
        }
        
        if let constant120FPS = defaults.object(forKey: "constant120FPS") as? Bool {
            self.constant120FPS = constant120FPS
        } else {
            self.constant120FPS = false // Default to false
        }
        
        /// ----------------------- Utils Settings -----------------------
        if let enableUtilsOption = defaults.object(forKey: "enableUtilsOption") as? Bool {
            self.enableUtilsOption = enableUtilsOption
        } else {
            self.enableUtilsOption = false
        }
        
        if let enableClipboardListener = defaults.object(forKey: "enableClipboardListener") as? Bool {
            self.enableClipboardListener = enableClipboardListener
        } else {
            self.enableClipboardListener = false
        }
        
        /// ----------------------- Quick Access Widget Settings -----------------------
        if let quickAccessWidgetSimpleDynamicRawValue = defaults.string(forKey: "quickAccessWidgetSimpleDynamic"),
           let quickAccessWidgetSimpleDynamic = QuickAccessType(rawValue: quickAccessWidgetSimpleDynamicRawValue) {
            self.quickAccessWidgetSimpleDynamic = quickAccessWidgetSimpleDynamic
        } else {
            self.quickAccessWidgetSimpleDynamic = .dynamic // Default to dynamic
        }
    }
    
    public func saveSettingsForDisplay(for screen: NSScreen) {
        self.selectedScreen = screen
        
        // Save the display ID of the selected screen
        if let displayID = screen.displayID {
            defaults.set(displayID, forKey: "selectedScreenID")
        }
    }
    
    // MARK: - Widget Update Logic
    
    /// Updates `selectedWidgets` and triggers a reload notification immediately
    /// This was a design choice to keep it in the settings page, this is becuase
    /// the settings is what manages and loads in the widgets at runtime and while
    /// the application is running
    func updateSelectedWidgets(with widgetName: String, isSelected: Bool) {
        
        debugLog("Updating selected widgets with: \(widgetName), isSelected: \(isSelected)", from: .settings)
        
        var limit = 2
        // LIMIT 3 Widgets Only
        if self.notchMaxWidth < 440 {
            limit = 1
        } else if self.notchMaxWidth < 520 {
            limit = 2
        } else if self.notchMaxWidth < 600 {
            limit = 3
        } else if self.notchMaxWidth < 700 {
            limit = 4
        } else {
            /// Simulates no limit
            limit = 20
        }
        
        print("Notch Min Width: \(notchMaxWidth) - Limit: \(limit)")
        
        // Starting With Remove Logic so we can clear out any old widgets
        
        if !isSelected {
            if selectedWidgets.contains(widgetName) {
                selectedWidgets.removeAll { $0 == widgetName }
                UIManager.shared.expandedWidgetStore.removeWidget(named: widgetName)
                debugLog("Removed widget: \(widgetName)", from: .settings)
            } else {
                debugLog("Widget \(widgetName) not found in selected widgets", from: .settings)
                exit(0)
            }
        }
        
        // Add Logic
        if isSelected {
            if selectedWidgets.count == limit { return }
            if !selectedWidgets.contains(widgetName) {
                selectedWidgets.append(widgetName)
                if let widget = WidgetRegistry.shared.getWidget(named: widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                    debugLog("Added widget: \(widgetName)", from: .settings)
                }
            }
        }
        
        saveSettings()
        debugLog("NEW Saved Settings: \(selectedWidgets)", from: .settings)
        
        UIManager.shared.displayCurrentBigPanelWidgets(with: "Updated Widgets")
        
        /// Refresh UI
        refreshUI()
    }
    
    // MARK: - UI Update Logic
    
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
        debugLog("🔄 Rebuilding widgets in the panel based on the updated order.", from: .settings)
        
        // Clear all currently displayed widgets
        UIManager.shared.expandedWidgetStore.clearWidgets()
        
        // Iterate over the updated selectedWidgets list
        for widgetName in selectedWidgets {
            if let widget = WidgetRegistry.shared.getWidget(named: widgetName) {
                UIManager.shared.addWidgetToBigPanel(widget)
            } else {
                debugLog("⚠️ Widget \(widgetName) not found in WidgetRegistry.", from: .settings)
            }
        }
        
        // Finally, refresh the UI
        refreshUI()
    }
}


// MARK: - Save Logic
extension SettingsModel {
    /// Saves the current settings to UserDefaults
    func saveSettings() {
        
        // Saving the last state for whatever widgets are selected
        defaults.set(selectedWidgets, forKey: "selectedWidgets")
        
        /// ----------------------- Camera Settings -----------------------
        defaults.set(isCameraFlipped, forKey: "isCameraFlipped")
        defaults.set(enableCameraOverlay, forKey: "enableCameraOverlay")
        if cameraOverlayTimer < 5 {
            cameraOverlayTimer = 5
        }
        defaults.set(cameraOverlayTimer, forKey: "cameraOverlayTimer")
        
        /// ----------------------- ClipBoard Settings -----------------------------------
        if clipboardManagerMaxHistory >= 0 {
            defaults.set(clipboardManagerMaxHistory, forKey: "clipboardManagerMaxHistory")
        }
        if clipboardManagerPollingIntervalMS >= 0 {
            defaults.set(clipboardManagerPollingIntervalMS, forKey: "clipboardManagerPollingIntervalMS")
        }
        /// ----------------------- Notch Settings -------------------------------------
        defaults.set(showDividerBetweenWidgets, forKey: "showDividerBetweenWidgets")
        
        
        defaults.set(notchScrollThreshold, forKey: "notchScrollThreshold")
        
        /// ----------------------- Display Settings -----------------------
        if let screen = selectedScreen {
            /// We Will Set the screen id
            defaults.set(screen.displayID, forKey: "selectedScreenID")
        }
    }
    
    
    // MARK: - Closed Notch Values
    /// Function to save the Closed Notch Values
    /// Called in GeneralSettings
    public func saveClosedNotchValues(values: ClosedNotchValues) {
        
        self.notchMinWidth = CGFloat(values.notchMinWidth)
        self.hoverTargetMode = values.hoverTargetMode
        self.enableButtonsOnHover = values.enableButtonsOnHover
        self.notchMinFallbackHeight = CGFloat(values.fallbackHeight)
        self.enableNotchHUD = values.hudEnabled
        self.oneFingerAction = values.oneFingerAction
        self.twoFingerAction = values.twoFingerAction
        
        /// Constraints
        if self.notchMinFallbackHeight <= 0 { self.notchMinFallbackHeight = 40 }
        /// Constraint The Notch Widths
        if notchMinWidth < MIN_NOTCH_MIN_WIDTH {
            notchMinWidth = MIN_NOTCH_MIN_WIDTH
        }
        if notchMinWidth > MAX_NOTCH_MIN_WIDTH {
            notchMinWidth = MAX_NOTCH_MIN_WIDTH
        }
        
        defaults.set(notchMinWidth, forKey: "notchMinWidth")
        defaults.set(hoverTargetMode.rawValue, forKey: "hoverTargetMode")
        defaults.set(enableButtonsOnHover, forKey: "enableButtonsOnHover")
        defaults.set(notchMinFallbackHeight, forKey: "notchMinFallbackHeight")
        defaults.set(enableNotchHUD, forKey: "enableNotchHUD")
        defaults.set(oneFingerAction.rawValue, forKey: "oneFingerAction")
        defaults.set(twoFingerAction.rawValue, forKey: "twoFingerAction")
    }
    
    // MARK: - Open Notch Dimensions
    /// Function to save the Open Notch Content Dimensions
    /// Called in GeneralSettings
    public func saveOpenNotchContentDimensions(values: OpenNotchContentDimensionsValues) {
        self.quickAccessWidgetDistanceFromLeft = CGFloat(values.leftSpacing)
        self.quickAccessWidgetDistanceFromTop = CGFloat(values.topSpacing)
        self.settingsWidgetDistanceFromRight = CGFloat(values.rightSpacing)
        self.notchMaxWidth = CGFloat(values.notchMaxWidth)
        
        defaults.set(quickAccessWidgetDistanceFromLeft, forKey: "quickAccessWidgetDistanceFromLeft")
        defaults.set(quickAccessWidgetDistanceFromTop, forKey: "quickAccessWidgetDistanceFromTop")
        defaults.set(settingsWidgetDistanceFromRight, forKey: "settingsWidgetDistanceFromRight")
        
        /// Constraint The Notch Widths
        if notchMaxWidth < MIN_NOTCH_MAX_WIDTH {
            notchMaxWidth = MIN_NOTCH_MAX_WIDTH
        }
        if notchMaxWidth > MAX_NOTCH_MAX_WIDTH {
            notchMaxWidth = MAX_NOTCH_MAX_WIDTH
        }
        
        defaults.set(notchMaxWidth, forKey: "notchMaxWidth")
    }
    
    
    // MARK: - Opening Animation
    /// Function to save the opening animations
    /// Called in AnimationSettings
    public func saveOpeningAnimationValues(values: OpeningAnimationSettingsValues) {
        self.openingAnimation = values.openingAnimation
        
        defaults.set(openingAnimation, forKey: "openingAnimation")
    }
    
    // MARK: - Metal Animations
    /// Function to save the metal animations
    /// Called in MetalAnimations
    public func saveMetalAnimationValues(values: MetalAnimationValues) {
        self.enableMetalAnimation = values.enableMetalAnimation
        self.notchBackgroundAnimation = values.notchBackgroundAnimation
        self.constant120FPS = values.constant120FPS
        
        defaults.set(enableMetalAnimation, forKey: "enableMetalAnimation")
        defaults.set(notchBackgroundAnimation.rawValue, forKey: "notchBackgroundAnimation")
        defaults.set(constant120FPS, forKey: "constant120FPS")
    }
    
    
    // MARK: - FileTray Settings
    /// Function to save the FileTray Settings
    /// Called in NotchNotchSettings with the fileTray
    public func saveFileTrayValues(values: FileTraySettingsValues) {
        guard let _ = values.fileTrayDefaultFolder else {
            print("⚠️ Invalid file tray default folder, not saving.")
            return
        }
        
        self.fileTrayAllowOpenOnLocalhost = values.fileTrayAllowOpenOnLocalhost
        self.localHostPin = values.localHostPin
        self.fileTrayPort = values.fileTrayPort
        
        /// Add Back Old FileTray Values
        func populateOldFiletrayValues(newFolder: URL, with oldFolder: URL?) {
            let fm = FileManager.default
            
            guard let oldFolder = oldFolder else {
                debugLog("ℹ️ No old folder to migrate from", from: .settings)
                return
            }
            
            guard newFolder.standardized != oldFolder.standardized else {
                debugLog("ℹ️ New and old folders are the same, skipping migration", from: .settings)
                return
            }
            
            guard newFolder != oldFolder else {
                debugLog("ℹ️ New and old folders are the same, skipping migration", from: .settings)
                return
            }
            
            // Check if old folder exists
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: oldFolder.path, isDirectory: &isDir), isDir.boolValue else {
                debugLog("ℹ️ Old folder doesn't exist or isn't a directory: \(oldFolder.path)", from: .settings)
                return
            }
            
            do {
                let items = try fm.contentsOfDirectory(at: oldFolder, includingPropertiesForKeys: nil)
                debugLog("📁 Found \(items.count) items to migrate from \(oldFolder.path)", from: .settings)
                
                for file in items {
                    let dest = newFolder.appendingPathComponent(file.lastPathComponent)
                    
                    if !fm.fileExists(atPath: dest.path) {
                        try fm.copyItem(at: file, to: dest)
                        debugLog("✅ Migrated: \(file.lastPathComponent)", from: .settings)
                    } else {
                        debugLog("⏭️ Skipped existing file: \(file.lastPathComponent)", from: .settings)
                    }
                }
            } catch {
                print("⚠️ Failed to migrate old file tray contents: \(error)")
            }
        }
        
        /// SAVING OF FILE LOGIC
        if let url = values.fileTrayDefaultFolder {
            let fm = FileManager.default
            var isDir: ObjCBool = false
            
            // Get the old folder from UserDefaults, not from the property
            let oldFolderPath = defaults.string(forKey: "fileTrayDefaultFolder")
            let oldFolder = oldFolderPath.map { URL(fileURLWithPath: $0) }
            
            if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                populateOldFiletrayValues(newFolder: url, with: oldFolder)
                defaults.set(url.path, forKey: "fileTrayDefaultFolder")
                fileTrayDefaultFolder = url
            } else {
                do {
                    try fm.createDirectory(at: url, withIntermediateDirectories: true)
                    populateOldFiletrayValues(newFolder: url, with: oldFolder)
                    defaults.set(url.path, forKey: "fileTrayDefaultFolder")
                    fileTrayDefaultFolder = url
                } catch {
                    print("❌ Couldn't create directory at \(url.path): \(error)")
                }
            }
        }
        /// ALLOWING OF SKIPPING FILES
        
        
        defaults.set(fileTrayAllowOpenOnLocalhost, forKey: "fileTrayAllowOpenOnLocalhost")
        
        /// Save Pin
        if localHostPin != "" {
            defaults.set(localHostPin, forKey: "localHostPin")
        } else {
            localHostPin = "1111" // Default pin
            defaults.set(localHostPin, forKey: "localHostPin")
        }
        
        /// Save Port
        if fileTrayPort > 0 && fileTrayPort < 65536 {
            defaults.set(fileTrayPort, forKey: "fileTrayPort")
        } else {
            fileTrayPort = 8000 // Default port
            defaults.set(fileTrayPort, forKey: "fileTrayPort")
        }
    }
    
    // MARK: - Messages Settings
    /// Function to save the Messages Settings
    /// Called in NotchNotchSettings with the Messages
    public func saveMessagesValues(values: MessagesSettingsValues) {
        self.enableMessagesNotifications = values.enableMessagesNotifications
        self.messagesHandleLimit = values.messagesHandleLimit
        self.messagesMessageLimit = values.messagesMessageLimit
        
        /// Messages Settings
        defaults.set(enableMessagesNotifications, forKey: "enableMessagesNotifications")
        if messagesHandleLimit < 10 {
            messagesHandleLimit = 10
        }
        defaults.set(messagesHandleLimit, forKey: "messagesHandleLimit")
        
        if messagesMessageLimit < 10 {
            messagesMessageLimit = 10
        }
        defaults.set(messagesMessageLimit, forKey: "messagesMessageLimit")
        
        
        /// Dont Want Running in Tests
        guard NSClassFromString("XCTest") == nil else { return }
        
        if NSClassFromString("XCTest") != nil {
            if self.enableMessagesNotifications {
                Task {
                    await MessagesManager.shared.checkFullDiskAccess()
                    await MessagesManager.shared.checkContactAccess()
                    await MessagesManager.shared.fetchAllHandles()
                    await MessagesManager.shared.startPolling()
                }
            } else {
                Task {
                    await MessagesManager.shared.stopPolling()
                }
            }
        }
    }
    
    
    // MARK: - Utils Settings
    /// Function to save the Utils Settings
    /// Called in NotchNotchSettings with the Utils
    public func saveUtilsValues(values: UtilsSettingsValues) {
        self.enableUtilsOption = values.enableUtilsOption
        self.enableClipboardListener = values.enableClipboardListener
        
        defaults.set(enableUtilsOption, forKey: "enableUtilsOption")
        defaults.set(enableClipboardListener, forKey: "enableClipboardListener")
        
        /// TODO: FIX: a bit bugged
        if self.enableClipboardListener {
            self.enableUtilsOption = true
            ClipboardManager.shared.start()
        } else {
            self.enableUtilsOption = false
            ClipboardManager.shared.stop()
        }
    }
    
    /// Quick Access Widget simple/Dynamic
    public func saveQuickAcessSimpleDynamic(values: QuickAccessStyleValues) {
        self.quickAccessWidgetSimpleDynamic = values.quickAccessWidgetSimpleDynamic
        
        defaults.set(quickAccessWidgetSimpleDynamic.rawValue, forKey: "quickAccessWidgetSimpleDynamic")
    }
    
    
    // MARK: - Events Section
    public func saveEventsValues(values: EventWidgetSettingsValues) {
        if values.eventWidgetScrollUpThreshold >= Int(MIN_EVENT_WIDGET_SCROLL_UP_THRESHOLD)
           && values.eventWidgetScrollUpThreshold <= Int(MAX_EVENT_WIDGET_SCROLL_UP_THRESHOLD)
        {
            self.eventWidgetScrollUpThreshold = CGFloat(values.eventWidgetScrollUpThreshold)
        }
        // Always persist the (possibly unchanged) current value
        defaults.set(eventWidgetScrollUpThreshold, forKey: "eventWidgetScrollUpThreshold")
    }
    
    // MARK: - Music Widget Section
    public func saveMusicWidgetValues(values: MusicPlayerSettingsValues) {
        self.showMusicProvider = values.showMusicProvider
        self.musicController = values.musicController
        self.overridenMusicProvider = values.overridenMusicProvider
        self.enableAlbumFlippingAnimation = values.enableAlbumFlippingAnimation
        
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.25)) {
            self.musicPlayerStyle = values.musicPlayerStyle
        }
        
        defaults.set(showMusicProvider, forKey: "showMusicProvider")
        defaults.set(musicController.rawValue, forKey: "musicController")
        defaults.set(overridenMusicProvider.rawValue, forKey: "overridenMusicProvider")
        defaults.set(musicPlayerStyle.rawValue, forKey: "musicPlayerStyle")
        defaults.set(enableAlbumFlippingAnimation, forKey: "enableAlbumFlippingAnimation")
    }
}
