
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
        let settings = SettingsModel.shared
        let widgetRegistry = WidgetRegistry.shared

        // Clear existing widgets from the UI
        UIManager.shared.bigWidgetStore.clearWidgets()

        print("Reloading widgets: \(settings.selectedWidgets)") // Debug print

        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {
                UIManager.shared.addWidgetToBigPanel(widget)

                // If the panel is closed, hide all widgets
                if UIManager.shared.panel_state == .CLOSED {
                    UIManager.shared.bigWidgetStore.hideWidget(named: widgetName)
                } else {
                    UIManager.shared.bigWidgetStore.showWidget(named: widgetName)
                }
            
                print("Added widget: \(widgetName)") // Debug print
            } else {
                print("Widget \(widgetName) not found in registry")
            }
        }

        // Force layout updates
        AudioManager.shared.startMediaTimer()
        UIManager.shared.big_panel.contentView?.needsLayout = true
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
    
        DispatchQueue.main.async {
            UIManager.shared.big_panel.contentView?.needsDisplay = true
        }
    }

    private func loadWidgetsFromSettings() {
        let settings = SettingsModel.shared
        let widgetRegistry = WidgetRegistry.shared

        // Clear existing widgets from the UI
        UIManager.shared.bigWidgetStore.clearWidgets()

        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {
                UIManager.shared.addWidgetToBigPanel(widget)
            
                // Only show widgets if the panel is open
                if UIManager.shared.panel_state == .CLOSED {
                    UIManager.shared.bigWidgetStore.hideWidget(named: widgetName)
                } else {
                    UIManager.shared.bigWidgetStore.showWidget(named: widgetName)
                }
            } else {
                print("Widget \(widgetName) not found in mappedWidgets")
            }
        }

        AudioManager.shared.startMediaTimer()
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
    }
}
