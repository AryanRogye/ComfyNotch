import AppKit


enum PanelState {
    case CLOSED
    case PARTIALLY_OPEN
    case OPEN
}

class UIManager {
    static let shared = UIManager()
    
    var panel: NSPanel!
    var panel_state : PanelState = .CLOSED

    var startPanelHeight: CGFloat = 0
    var startPanelWidth: CGFloat = 300
    
    private init() {
        startPanelHeight = getNotchHeight()
        AudioManager.shared.getNowPlayingInfo()
    }

    func setupFrame() {
        guard let screen = NSScreen.main else { return }
        // Full screen, not visibleFrame
        let screenFrame = screen.frame
        let notchHeight = getNotchHeight()

        let panelRect = NSRect(
            // Position it near the top of the screen
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - startPanelHeight - 2,
            width: startPanelWidth,
            height: notchHeight 
        )

        panel = NSPanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],  // Completely frameless
            backing: .buffered,
            defer: false
        )

        panel.title = "ComfyNotch"
        panel.level = .screenSaver  // Stays visible even over fullscreen apps
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .black.withAlphaComponent(0.9)
        panel.ignoresMouseEvents = false  // Allow interaction
        panel.hasShadow = false  // Remove shadow to make it seamless

        panel.makeKeyAndOrderFront(nil)

        // Set the WidgetManager's panel content view
        if let contentView = panel.contentView {
            WidgetManager.shared.setPanelContentView(contentView)
        }
    }

    func hideWidgets() {
        WidgetManager.shared.hideWidgets()
        panel.contentView?.layoutSubtreeIfNeeded() // Force layout update
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