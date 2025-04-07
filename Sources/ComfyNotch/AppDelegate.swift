
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
        print("Done loading widgets from settings")


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
    // TODO: Issue In Here
    @objc private func reloadWidgets() {
        let settings = SettingsModel.shared
        let widgetRegistry = WidgetRegistry.shared

        print("Reloading widgets: \(settings.selectedWidgets)")

        let currentlyAddedWidgets = UIManager.shared.bigWidgetStore.widgets.map { $0.widget.name }

        // Remove widgets that are no longer selected
        for existingWidget in currentlyAddedWidgets {
            if !settings.selectedWidgets.contains(existingWidget) {
                UIManager.shared.bigWidgetStore.hideWidget(named: existingWidget)
            }
        }

        // Add or update widgets that are selected
        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {
                if !currentlyAddedWidgets.contains(widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                }
            
                // Only show widgets if the panel is open
                if UIManager.shared.panel_state == .OPEN {
                    print("Showing widget: \(widgetName)")
                    UIManager.shared.bigWidgetStore.showWidget(named: widgetName)
                }
            } else {
                print("Widget \(widgetName) not found in registry")
            }
        }

        AudioManager.shared.startMediaTimer()
        UIManager.shared.big_panel.contentView?.needsLayout = true
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()

        DispatchQueue.main.async {
            UIManager.shared.big_panel.contentView?.needsDisplay = true
        }
    }

    private func loadWidgetsFromSettings() {
        print("Loading Widgets From Settings")
        let settings = SettingsModel.shared
        let widgetRegistry = WidgetRegistry.shared

        // Get the current list of widgets in the store
        let existingWidgets = UIManager.shared.bigWidgetStore.widgets.map { $0.widget.name }
        // Remove widgets that are not selected anymore
        for widgetName in existingWidgets {
            if !settings.selectedWidgets.contains(widgetName) {
                UIManager.shared.bigWidgetStore.hideWidget(named: widgetName)
            }
        }

        // Add or show selected widgets
        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {


                if !existingWidgets.contains(widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                }

                // Show or hide depending on the panel state
                if UIManager.shared.panel_state == .OPEN {
                    UIManager.shared.bigWidgetStore.showWidget(named: widgetName)
                } else {
                    UIManager.shared.bigWidgetStore.hideWidget(named: widgetName)
                }
            } else {
                print("Widget \(widgetName) not found in WidgetRegistry")
            }
        }

        // Force layout refresh
        AudioManager.shared.startMediaTimer()
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()

        DispatchQueue.main.async {
            UIManager.shared.big_panel.contentView?.needsDisplay = true
        }
    }
}
