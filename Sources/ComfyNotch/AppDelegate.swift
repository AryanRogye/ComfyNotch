
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hoverHandler: HoverHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UIManager.shared.setupFrame()
        ScrollManager.shared.start()
        if let smallPanel = UIManager.shared.small_panel {
            self.hoverHandler = HoverHandler(panel: smallPanel)
        }

        loadWidgetsFromSettings()

        AudioManager.shared.startMediaTimer()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadWidgets),
            name: NSNotification.Name("ReloadWidgets"),
            object: nil
        )
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
            print("Removing widget: \(widget.name)")
            UIManager.shared.bigPanelWidgetManager.removeWidget(widget)
        }

        for widgetName in settings.selectedWidgets {
            if let widget = settings.mappedWidgets[widgetName] {
                print("Adding widget: \(widgetName)")
                UIManager.shared.addWidgetToBigPanel(widget)
                widget.show()  // Make sure the widget is not hidden
            } else {
                print("Widget \(widgetName) not found in mappedWidgets")
            }
        }

        // Force layout refresh
        UIManager.shared.bigPanelWidgetManager.layoutWidgets()
        UIManager.shared.big_panel.contentView?.layoutSubtreeIfNeeded()
    }
}
