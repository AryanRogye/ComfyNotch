import AppKit


enum PanelState {
    case CLOSED
    case PARTIALLY_OPEN
    case OPEN
}

class UIManager {
    static let shared = UIManager()

    var small_panel : NSPanel!
    var big_panel : NSPanel!
    
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

        big_panel = NSPanel(
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
            WidgetManager.shared.setPanelContentView(contentView)
        }

        big_panel.makeKeyAndOrderFront(nil)
    }

    func hideWidgets() {
        WidgetManager.shared.hideWidgets()
        big_panel.contentView?.layoutSubtreeIfNeeded() // Force layout update
    }

    func showWidgets() {
        WidgetManager.shared.showWidgets()
    }

    func addWidget(_ widget: Widget) {
        print("Adding widget: \(widget.name)")
        WidgetManager.shared.addWidget(widget)
    }

    func getNotchHeight() -> CGFloat {
        if let screen = NSScreen.main {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.top
        }
        return 0
    }
}