
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hoverHandler: HoverHandler?
    private var panelProximityHandler: PanelProximityHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = SettingsModel.shared

        // Start the UI
        UIManager.shared.setupFrame()
        // Allow Scroll Handler to listen to scroll events
        ScrollHandler.shared.start()
        if let smallPanel = UIManager.shared.small_panel {
            // Tiny Haptic Feedback when hovering
            self.hoverHandler = HoverHandler(panel: smallPanel)
        }
        if let bigPanel = UIManager.shared.big_panel {
            // Proximity Handler for the Big Panel
            self.panelProximityHandler = PanelProximityHandler(panel: bigPanel)
        }

        // Set up the ui by loading the widgets from settings onto it
        loadWidgetsFromSettings()


        // Useful for the settings to let the app know when to reload widgets
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadWidgets),
            name: NSNotification.Name("ReloadWidgets"),
            object: nil
        )
        // Any Screen errors that may happen, is handled in here
        DisplayHandler.shared.start()
    }

    // This method is called to reload widgets when the settings change
    @objc private func reloadWidgets() {
        loadWidgetsFromSettings()
        // UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
        // UIManager.shared.bigPanelWidgetManager.layoutWidgets()
    }

    // This method is called to load widgets from the settings
    private func loadWidgetsFromSettings() {
        let settings = SettingsModel.shared
        let widgetRegistry = WidgetRegistry.shared


        // Clear existing widgets
        UIManager.shared.bigWidgetStore.clearWidgets()

        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {
                UIManager.shared.addWidgetToBigPanel(widget)
                UIManager.shared.bigWidgetStore.showWidget(named: widgetName)
            } else {
                print("Widget \(widgetName) not found in mappedWidgets")
            }
        }
        
        AudioManager.shared.startMediaTimer()

        // Force layout refresh
        // UIManager.shared.bigPanelWidgetManager.layoutWidgets()
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
    }
}
