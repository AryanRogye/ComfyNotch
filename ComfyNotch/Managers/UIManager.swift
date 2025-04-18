import AppKit
import SwiftUI

/**
 * Represents the current state of the panel display.
 */
enum PanelState {
    case closed
    case partiallyOpen
    case open
}

/**
 * Custom NSPanel subclass that can become key and main window.
 * Enables proper focus and interaction handling.
 */
class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    override var canBecomeMain: Bool {
        return true
    }
}


/// Class used for the Window
class NotchWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    /// NSWindow's internal has a scrollWheel which we will use to listen for
    /// any scroll action done onto the Notch Window
//    override func scrollWheel(with event: NSEvent) {
//        /// This makes sure that the scroll wheel behaves like a normal scroll wheel
//        super.scrollWheel(with: event)
//        /// Let the Scroll Handler handle any "Scroll" events
//        /// we pass in self so it can control ourselves
//        ScrollHandler.shared.handle(event, for: self)
//    }
}

/**
 * UIManager handles the core UI components of the application.
 * Responsible for managing panels, widget stores, and panel states.
 *
 * Key Components:
 * - Small Panel: Displays compact widgets in the notch area
 * - Big Panel: Shows expanded widgets and additional functionality
 * - Widget Stores: Manages widget collections for both panels
 */
class UIManager {
    static let shared = UIManager()
    let smallWidgetStore = SmallPanelWidgetStore()
    let bigWidgetStore = BigPanelWidgetStore()
    let priorityPanelWidgetStore = BigPanelWidgetStore()

    var hoverHandler: HoverHandler?

    var userNotch: NotchWindow!
    var bigPanel: NSPanel!

    var smallPanelWidgetManager = SmallPanelWidgetManager()
    var bigPanelWidgetManager = BigPanelWidgetManager()

    var panelState: PanelState = .closed

    var startPanelHeight: CGFloat = 0
    var startPanelWidth: CGFloat = 320

    var startPanelYOffset: CGFloat = 0

    /**
     * Initializes the UI manager and sets up initial dimensions.
     * Configures panel height based on notch size and initializes audio components.
     */
    private init() {
        startPanelHeight = getNotchHeight()
        AudioManager.shared.getNowPlayingInfo()
    }

    /**
     * Sets up both small and big panels with their initial configurations.
     */
    func setupFrame() {
        setupSmallPanel()
        // setupBigPanel()
    }
    
    func showBigPanel() {
        bigPanel.animator().alphaValue = 1
        bigPanel.orderFrontRegardless()
    }

    func hideBigPanel() {
        bigPanel.animator().alphaValue = 0
        bigPanel.orderOut(nil)
    }

    /**
     * Configures the small panel that sits in the notch area.
     * Initializes default widgets and sets up panel properties.
     */
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

        userNotch = NotchWindow(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        userNotch.title = "ComfyNotch"
        userNotch.level = .screenSaver
        userNotch.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        userNotch.isMovableByWindowBackground = false
        userNotch.backgroundColor = .clear
        userNotch.isOpaque = false
        userNotch.hasShadow = false

        // Create and add widgets to the store
//        let albumWidgetModel = AlbumWidgetModel()
//        let movingDotsModel = MovingDotsViewModel()
//        let currentSongWidgetModel = MusicPlayerWidgetModel()
//
//        /// Create Widgets for the small panel
//        let albumWidget = AlbumWidgetView(model: albumWidgetModel)
//        let movingDotsWidget = MovingDotsView(model: movingDotsModel)
//        let settingsWidget = SettingsButtonView()
//
//        /// Create Widgets for the priority panel
//        let currentSongWidget = CurrentSongWidget(
//            model: currentSongWidgetModel,
//            movingDotsModel: movingDotsModel
//        )
//
//        // Add Widgets to the WidgetStore
//        smallWidgetStore.addWidget(albumWidget)
//        smallWidgetStore.addWidget(movingDotsWidget)
//        smallWidgetStore.addWidget(settingsWidget)
//
//        // Add Widgets to the PriorityPanel
//        priorityPanelWidgetStore.addWidget(currentSongWidget)
//        priorityPanelWidgetStore.showWidget(named: "CurrentSongWidget")

        let contentView = SmallPanelWidgetManager()
            .environmentObject(smallWidgetStore)
            .environmentObject(priorityPanelWidgetStore)

        userNotch.contentView = NSHostingView(rootView: contentView)
        userNotch.makeKeyAndOrderFront(nil)

        // smallPanel.orderFrontRegardless()
    }

    /**
     * Configures the expandable big panel for additional widgets.
     * Sets up panel properties and initial widget layout.
     */
    func setupBigPanel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let notchHeight = getNotchHeight()  // Same height as smallPanel

        let panelRect = NSRect(
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - notchHeight - startPanelYOffset,
            width: startPanelWidth,
            height: notchHeight  // Same starting height as smallPanel
        )

        bigPanel = FocusablePanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        bigPanel.title = "ComfyNotch Big Panel"
        bigPanel.level = .screenSaver
        bigPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        bigPanel.isMovableByWindowBackground = false
        bigPanel.backgroundColor = .clear
        bigPanel.isOpaque = false
        bigPanel.hasShadow = false

        let contentView = BigPanelWidgetManager()
            .environmentObject(bigWidgetStore)

        bigPanel.contentView = NSHostingView(rootView: contentView)
//        bigPanel.makeKeyAndOrderFront(nil)
        bigPanel.orderFrontRegardless()

        hideBigPanelWidgets() // Ensure initial state is correct
    }

    /**
     * Widget visibility management methods for the small panel.
     * Controls the display of settings and other widgets.
     */
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

    /**
     * Widget visibility management methods for the big panel.
     * Controls the display state of all big panel widgets.
     */
    func hideBigPanelWidgets() {
        bigWidgetStore.hideWidget(named: "MusicPlayerWidget")
        bigWidgetStore.hideWidget(named: "TimeWidget")
        bigWidgetStore.hideWidget(named: "NotesWidget")
        bigWidgetStore.hideWidget(named: "CameraWidget")
        bigWidgetStore.hideWidget(named: "AIChatWidget")
        
        hideBigPanel()
        
        userNotch.orderFrontRegardless()
        userNotch.level = .screenSaver
    }

    func showBigPanelWidgets() {
        bigWidgetStore.showWidget(named: "MusicPlayerWidget")
        bigWidgetStore.showWidget(named: "TimeWidget")
        bigWidgetStore.showWidget(named: "NotesWidget")
        bigWidgetStore.showWidget(named: "CameraWidget")
        bigWidgetStore.showWidget(named: "AIChatWidget")

        bigPanel.contentView?.layoutSubtreeIfNeeded()
    }

    private func displayCurrentBigPanelWidgets(with title: String = "Current Big Panel Widgets") {
        print("=====================================================")
        print("\(title)")
        print("=====================================================")
        for widget in bigWidgetStore.widgets {
            print("Name: \(widget.widget.name), Visible: \(widget.isVisible)")
        }
        print("=====================================================")
    }

    /**
     * Utility methods for widget management and panel dimensions.
     */
    func addWidgetToBigPanel(_ widget: Widget) {
        bigWidgetStore.addWidget(widget)
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
