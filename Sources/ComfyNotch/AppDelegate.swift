import AppKit
import MediaPlayer
import CoreAudio
import Foundation

/**
 * AppDelegate manages the application lifecycle and initialization of core components.
 * Responsible for setting up the UI, handlers, and loading widget configurations.
 *
 * Properties:
 * - hoverHandler: Manages hover interactions for the small panel
 * - panelProximityHandler: Manages proximity-based interactions for the big panel
 */
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var hoverHandler: HoverHandler?
    private var panelProximityHandler: PanelProximityHandler?

    /**
     * Called when the application finishes launching.
     * Initializes core components and sets up the UI infrastructure.
     *
     * Setup sequence:
     * 1. Initializes settings
     * 2. Sets up UI frame
     * 3. Starts scroll event handling
     * 4. Configures panel handlers
     * 5. Loads widget configurations
     * 6. Starts display monitoring
     *
     * - Parameter notification: Launch notification object
     */
    public func applicationDidFinishLaunching(_ notification: Notification) {
        _ = SettingsModel.shared

        // Start the UI
        UIManager.shared.setupFrame()

        if let smallPanel = UIManager.shared.smallPanel {
            // Tiny Haptic Feedback when hovering
            self.hoverHandler = HoverHandler(panel: smallPanel)
        }
        if let smallPanel = UIManager.shared.smallPanel {
            // Proximity Handler for the Big Panel
            self.panelProximityHandler = PanelProximityHandler(panel: smallPanel)
        }

        // Set up the ui by loading the widgets from settings onto it
        loadWidgetsFromSettings()

        // Any Screen errors that may happen, is handled in here
        DisplayHandler.shared.start()
        // Start listening for shortcuts
        ShortcutHandler.shared.startListening()
        ScrollHandler.shared.openFull()
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
        let existingWidgets = UIManager.shared.bigWidgetStore.widgets.map { $0.widget.name }
        // Remove widgets that are not selected anymore
        for widgetName in existingWidgets where !settings.selectedWidgets.contains(widgetName) {
            UIManager.shared.bigWidgetStore.hideWidget(named: widgetName)
        }

        // Add or show selected widgets
        for widgetName in settings.selectedWidgets {
            if let widget = widgetRegistry.getWidget(named: widgetName) {

                if !existingWidgets.contains(widgetName) {
                    UIManager.shared.addWidgetToBigPanel(widget)
                }

                // Show or hide depending on the panel state
                if UIManager.shared.panelState == .open {
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
        UIManager.shared.smallPanel.contentView?.layoutSubtreeIfNeeded()

        DispatchQueue.main.async {
            UIManager.shared.smallPanel.contentView?.needsDisplay = true
        }
    }
}
