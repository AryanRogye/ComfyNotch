
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hoverHandler: HoverHandler?
    private var panelProximityHandler: PanelProximityHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UIManager.shared.setupFrame()
        ScrollHandler.shared.start()
        if let smallPanel = UIManager.shared.small_panel {
            self.hoverHandler = HoverHandler(panel: smallPanel)
        }
        if let bigPanel = UIManager.shared.big_panel {
            self.panelProximityHandler = PanelProximityHandler(panel: bigPanel)
        }

        loadWidgetsFromSettings()


        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadWidgets),
            name: NSNotification.Name("ReloadWidgets"),
            object: nil
        )
        DisplayHandler.shared.start()
    }

    @objc private func reloadWidgets() {
        loadWidgetsFromSettings()
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
        UIManager.shared.bigPanelWidgetManager.layoutWidgets()
    }

    private func loadWidgetsFromSettings() {
        let settings = SettingsModel.shared

        // Clear existing widgets
        UIManager.shared.bigPanelWidgetManager.widgets.forEach { widget in
            UIManager.shared.bigPanelWidgetManager.removeWidget(widget)
        }

        for widgetName in settings.selectedWidgets {
            if let widget = settings.mappedWidgets[widgetName] {
                UIManager.shared.addWidgetToBigPanel(widget)
                widget.show()  // Make sure the widget is not hidden
            } else {
                print("Widget \(widgetName) not found in mappedWidgets")
            }
        }
        
        AudioManager.shared.startMediaTimer()

        // Force layout refresh
        UIManager.shared.bigPanelWidgetManager.layoutWidgets()
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
    }
}
