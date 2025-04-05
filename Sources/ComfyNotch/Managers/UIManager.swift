import AppKit
import SwiftUI


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
    let smallWidgetStore = SmallPanelWidgetStore()
    let bigWidgetStore = BigPanelWidgetStore()

    var small_panel : NSPanel!
    var big_panel : NSPanel!

    var smallPanelWidgetManager = SmallPanelWidgetManager()
    var bigPanelWidgetManager = BigPanelWidgetManager()

 
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
        small_panel.backgroundColor = .clear
        small_panel.isOpaque = false
        small_panel.hasShadow = false
 
        // Create and add widgets to the store
        let albumWidgetModel = AlbumWidgetModel()
        let movingDotsModel = MovingDotsViewModel()
        let settingsWidgetModel = SettingsWidgetModel()

        let albumWidget = AlbumWidgetView(model: albumWidgetModel)

        let movingDotsWidget = MovingDotsView(model: movingDotsModel)

        let settingsWidget = SettingsButtonView(model: settingsWidgetModel)

        // Add Widgets to the WidgetStore
        smallWidgetStore.addWidget(albumWidget)
        smallWidgetStore.addWidget(movingDotsWidget)
        smallWidgetStore.addWidget(settingsWidget)

        let contentView = SmallPanelWidgetManager()
            .environmentObject(smallWidgetStore)
        
        small_panel.contentView = NSHostingView(rootView: contentView)
        small_panel.makeKeyAndOrderFront(nil)

        hideSmallPanelSettingsWidget() // Ensure initial state is correct
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
        big_panel.backgroundColor = .clear
        big_panel.isOpaque = false
        big_panel.hasShadow = false

        let contentView = BigPanelWidgetManager()
            .environmentObject(bigWidgetStore)

        big_panel.contentView = NSHostingView(rootView: contentView)
        big_panel.makeKeyAndOrderFront(nil)
    }


    // HIDE/SHOW SMALL PANEL
    func hideSmallPanelSettingsWidget() {
        smallWidgetStore.hideWidget(named: "Settings")
        smallWidgetStore.showWidget(named: "AlbumWidget")
        smallWidgetStore.showWidget(named: "MovingDotsWidget")
    }

    func showSmallPanelSettingsWidget() {
        smallWidgetStore.showWidget(named: "Settings")
        smallWidgetStore.showWidget(named: "AlbumWidget")
        smallWidgetStore.hideWidget(named: "MovingDotsWidget")
    }


    // BIG PANEL VIEWS
    func hideBigPanelWidgets() {
        // bigPanelWidgetManager.hideWidgets()
        big_panel.contentView?.layoutSubtreeIfNeeded()

        small_panel.makeKeyAndOrderFront(nil)
        small_panel.level = .screenSaver
    }

    func showBigPanelWidgets() {
        // bigPanelWidgetManager.showWidgets()
    }

    // ADDING TO WIDGETS
    func addWidgetToBigPanel(_ widget: Widget) {
        // bigPanelWidgetManager.addWidget(widget)
    }
    func addWidgetsToSmallPanel(_ widget: Widget) {
        // smallPanelWidgetManager.addWidget(widget)
    }

    func getNotchHeight() -> CGFloat {
        if let screen = NSScreen.main {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.top
        }
        return 0
    }
}