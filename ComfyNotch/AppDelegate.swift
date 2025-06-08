import AppKit
import MediaPlayer
import CoreAudio
import Foundation
import EventKit

// _ = SettingsModel.shared


/**
 * AppDelegate manages the application lifecycle and initialization of core components.
 * Responsible for setting up the UI, handlers, and loading widget configurations.
 *
 * Properties:
 * - hoverHandler: Manages hover interactions for the small panel
 * - panelProximityHandler: Manages proximity-based interactions for the big panel
 */
public class AppDelegate: NSObject, NSApplicationDelegate {
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
        let _ = {
            NSKeyedUnarchiver.setClass(NSAttributedString.self, forClassName: "__NSCFAttributedString")
            NSKeyedUnarchiver.setClass(NSAttributedString.self, forClassName: "NSConcreteAttributedString")
            NSKeyedUnarchiver.setClass(NSAttributedString.self, forClassName: "NSFrozenAttributedString")
        }()
        _ = SettingsModel.shared
        
        /// Close the SettingsPage On Launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if let window = NSApp.windows.first(where: { $0.title == "SettingsView" }) {
                window.performClose(nil)
                window.close()
            }
        }
        
        if SettingsModel.shared.enableMessagesNotifications {
            Task {
                /// Check At start so no weird UI bug
                MessagesManager.shared.checkFullDiskAccess()
                MessagesManager.shared.checkContactAccess()
                await MessagesManager.shared.fetchAllHandles()
                MessagesManager.shared.startPolling()
            }
        }
        
        /// Wanna Request Access To Acessibility
        MediaKeyInterceptor.shared.requestAccessibilityIfNeeded()

        EventManager.shared.requestPermissionEventsIfNeededOnce { granted in
            DispatchQueue.main.async {
                if !granted {
                    // Temporarily show the app so macOS lets us ask for permissions
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    // Go back to your usual background style
                    NSApp.setActivationPolicy(.prohibited)
                    NSApp.activate(ignoringOtherApps: true)
                }
                // Start the UI
                self.launchComfyNotch()
            }
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate")
        MediaKeyInterceptor.shared.stop()
        VolumeManager.shared.stop()
        BrightnessWatcher.shared.stop()
        ClipboardManager.shared.stop()
        DisplayManager.shared.stop()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func launchComfyNotch() {
        /// Start A Display Manager, this will be used by the ui manager
        DisplayManager.shared.start()
        
        UIManager.shared.setupFrame()
        
        if let smallPanel = UIManager.shared.smallPanel {
            // Proximity Handler for the Big Panel
            self.panelProximityHandler = PanelProximityHandler(panel: smallPanel)
        }
        
        /// Begin The Clipboard Manger
        ClipboardManager.shared.start()
        /// Start the hover handler, this also listens for music playing closing and opening slightly
        PanelAnimator.shared.startAnimationListeners()
        
        if SettingsModel.shared.enableNotchHUD {
            /// Start The Media Key Interceptor
            MediaKeyInterceptor.shared.start()
            /// Start Volume Manager
            VolumeManager.shared.start()
            BrightnessWatcher.shared.start()
        }
        
        // Set up the ui by loading the widgets from settings onto it
        self.loadWidgetsFromSettings()
        
        // Any Screen errors that may happen, is handled in here
        DisplayHandler.shared.start()
        // Start listening for shortcuts
        ShortcutHandler.shared.startListening()
        
        UIManager.shared.applyCompactWidgetLayout()
        ScrollHandler.shared.closeFull()
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

        DispatchQueue.main.async {
            UIManager.shared.smallPanel.contentView?.needsDisplay = true
        }
    }
}
