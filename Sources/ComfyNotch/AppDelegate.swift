
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hoverHandler: HoverHandler?
    private var panelProximityHandler: PanelProximityHandler?

    /// This function is called when the app is launched
    /// - Parameter notification: The notification object telling us the app has launched
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

        // Any Screen errors that may happen, is handled in here
        DisplayHandler.shared.start()
    }

    /// This function is called when the app is started to load in the widgets
    /// I could add this to the UIManager but I think it makes more sense to have it here
    /// it means after "everything" is setup, we can then start loading in the widgets,
    /// this confirms to us that everything is ok and nothing is broken
    private func loadWidgetsFromSettings() {
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
