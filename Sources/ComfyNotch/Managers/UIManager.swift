import AppKit


enum PanelState {
    case CLOSED
    case PARTIALLY_OPEN
    case OPEN
}

class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    override var canBecomeMain: Bool {
        return true
    }
}

class UIManager {
    static let shared = UIManager()

    var small_panel : NSPanel!
    var big_panel : NSPanel!

    var bigPanelWidgetManager = BigPanelWidgetManager()
    var smallPanelWidgetManager = SmallPanelWidgetManager()
    
    var panel_state : PanelState = .CLOSED

    var startPanelHeight: CGFloat = 0
    var startPanelWidth: CGFloat = 300

    var startPanelYOffset: CGFloat = 0
    
    private init() {
        startPanelHeight = getNotchHeight()
        AudioManager.shared.getNowPlayingInfo()
    }

    func setupFrame() {
        setupBigPanel()
        setupSmallPanel()
    }

    func setupSmallPanel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let notchHeight = getNotchHeight()

        let panelRect = NSRect(
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - notchHeight - startPanelYOffset,
            width: startPanelWidth,
            height: notchHeight
        )

        small_panel = NSPanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        small_panel.title = "ComfyNotch"
        small_panel.level = .screenSaver
        small_panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        small_panel.isMovableByWindowBackground = false
        small_panel.backgroundColor = .black.withAlphaComponent(1)
        small_panel.isOpaque = false
        small_panel.hasShadow = false

        if let contentView = small_panel.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true

            smallPanelWidgetManager.setPanelContentView(contentView)

            // Now add the settings widget AFTER the panel is set up
            let settingsWidget = SettingsWidget()
            settingsWidget.alignment = .right

            let closedAlbumWidget = ClosedAlbumWidget()
            closedAlbumWidget.alignment = .left

            let movingDotsWidget = MovingDotsWidget()
            movingDotsWidget.alignment = .right


            smallPanelWidgetManager.addWidget(closedAlbumWidget)
            smallPanelWidgetManager.addWidget(settingsWidget)
            smallPanelWidgetManager.addWidget(movingDotsWidget)

            // Layout widgets
            smallPanelWidgetManager.layoutWidgets()
            smallPanelWidgetManager.logAllConstraints()
        }

        small_panel.makeKeyAndOrderFront(nil)
    }

    func setupBigPanel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let notchHeight = getNotchHeight()  // Same height as small_panel

        let panelRect = NSRect(
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - notchHeight - startPanelYOffset,
            width: startPanelWidth,
            height: notchHeight  // Same starting height as small_panel
        )

        big_panel = FocusablePanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        big_panel.title = "ComfyNotch Big Panel"
        big_panel.level = .screenSaver
        big_panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        big_panel.isMovableByWindowBackground = false
        big_panel.backgroundColor = .black.withAlphaComponent(1)
        big_panel.isOpaque = false
        big_panel.hasShadow = false

        if let contentView = big_panel.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true

            // border color of grey

            // THIS IS WHERE THE WIDGETS GO
            bigPanelWidgetManager.setPanelContentView(contentView)
        }

        big_panel.makeKeyAndOrderFront(nil)
    }


    // HIDE/SHOW SMALL PANEL
    func hideSmallPanelSettingsWidget() {
        let widgets = smallPanelWidgetManager.widgets

        for widget in widgets {
            if widget.name == "Settings" {
                widget.hide()
            } else if widget.name == "ClosedAlbumWidget" {
                widget.show()
            } else if widget.name == "MovingDotsWidget" {
                widget.show()
            }
        }

        small_panel.contentView?.layoutSubtreeIfNeeded()
    }
    func showSmallPanelSettingsWidget() {
        let widgets = smallPanelWidgetManager.widgets

        for widget in widgets {
            if widget.name == "Settings" {
                widget.show()
            } else if widget.name == "ClosedAlbumWidget" {
                widget.hide()
            } else if widget.name == "MovingDotsWidget" {
                widget.hide()
            }
        }
    }


    // BIG PANEL VIEWS
    func hideBigPanelWidgets() {
        bigPanelWidgetManager.hideWidgets()
        big_panel.contentView?.layoutSubtreeIfNeeded()

        small_panel.makeKeyAndOrderFront(nil)
        small_panel.level = .screenSaver
    }

    func showBigPanelWidgets() {
        bigPanelWidgetManager.showWidgets()
    }

    // ADDING TO WIDGETS
    func addWidgetToBigPanel(_ widget: Widget) {
        bigPanelWidgetManager.addWidget(widget)
    }
    func addWidgetsToSmallPanel(_ widget: Widget) {
        smallPanelWidgetManager.addWidget(widget)
    }

    func getNotchHeight() -> CGFloat {
        if let screen = NSScreen.main {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.top
        }
        return 0
    }
}