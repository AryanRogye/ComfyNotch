//
//  AppCoordinator.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/24/25.
//

@MainActor
class AppCoordinator {
    
    private let windowCoordinator: WindowCoordinator
    private let settingsCoordinator: SettingsCoordinator
    
    private var comfyNotchSpaceManager: ComfyNotchSpaceManager?
    
    private var uiManager: UIManager = .shared
    private var messagesManager: MessagesManager = .shared
    
    private var started: Bool = false
    
    init() {
        self.windowCoordinator = WindowCoordinator()
        self.settingsCoordinator = SettingsCoordinator(windows: windowCoordinator)
        
        self.comfyNotchSpaceManager = ComfyNotchSpaceManager()
        uiManager.assignSpaceManager(self.comfyNotchSpaceManager)
        uiManager.assignSettingsCoordinator(self.settingsCoordinator)
        messagesManager.start()
    }

    public func start() {
        
        if started {
            print("Cant Start AppCoordinator twice")
            return
        }
        started = true
        
        /// Start A Display Manager, this will be used by the ui manager
        DisplayManager.shared.start()
        
        /// Start the panels
        UIManager.shared.start()
        
        /// Begin The Clipboard Manger
        ClipboardManager.shared.start()
        
        SettingsModel.shared.hudManager.start()
        
        // Set up the ui by loading the widgets from settings onto it
        self.loadWidgetsFromSettings()
        
        // Any Screen errors that may happen, is handled in here
        DisplayHandler.shared.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIManager.shared.re_align_notch()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIManager.shared.applyCompactWidgetLayout()
        }
    }
    
    public func end() {
        SettingsModel.shared.hudManager.stop()
        ClipboardManager.shared.stop()
        DisplayManager.shared.stop()
        MessagesManager.shared.stop()
        started = false
    }
    
    
    /**
     * Loads and configures widgets based on user settings.
     * This method ensures all system components are properly initialized
     * before loading widgets.
     *
     * Process:
     * 1. Gets current widget configuration from settings
     * 2. Removes deselected widgets
     * 3. Adds or shows selected widgets
     * 4. Updates widget visibility based on panel state
     * 5. Refreshes layout and display
     */
    private func loadWidgetsFromSettings() {
        let settings = SettingsModel.shared
        let widgetRegistry = WidgetRegistry.shared
        
        // Get the current list of widgets in the store
        let existingWidgets = UIManager.shared.expandedWidgetStore.widgets.map { $0.widget.name }
        // Remove widgets that are not selected anymore
        for widgetName in existingWidgets where !settings.selectedWidgets.contains(widgetName) {
            UIManager.shared.expandedWidgetStore.hideWidget(named: widgetName)
        }
        
        // Add or show selected widgets
        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {
                
                if !existingWidgets.contains(widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                }
                
                // Show or hide depending on the panel state
                if UIManager.shared.panelState == .open {
                    UIManager.shared.expandedWidgetStore.showWidget(named: widgetName)
                } else {
                    UIManager.shared.expandedWidgetStore.hideWidget(named: widgetName)
                }
            } else {
                debugLog("Widget \(widgetName) not found in WidgetRegistry")
            }
        }
        
        // Force layout refresh
        AudioManager.shared.startMediaTimer()
        UIManager.shared.smallPanel.contentView?.layoutSubtreeIfNeeded()
        
        UIManager.shared.smallPanel.contentView?.needsDisplay = true
    }
}
