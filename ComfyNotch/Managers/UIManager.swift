import AppKit
import SwiftUI
import CoreGraphics

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
    let compactWidgetStore = CompactWidgetsStore()
    let expandedWidgetStore = ExpandedWidgetsStore()

    var smallPanel: NSPanel!

    var panelState: PanelState = .closed

    var startPanelHeight: CGFloat = 0
    var startPanelWidth: CGFloat = 300

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
    }

    /**
     * Configures the small panel that sits in the notch area.
     * Initializes default widgets and sets up panel properties.
     */
    func setupSmallPanel() {
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        let screenFrame = screen.frame
        let notchHeight = getNotchHeight()

        let panelRect = NSRect(
            x: (screenFrame.width - startPanelWidth) / 2,
            y: screenFrame.height - notchHeight - startPanelYOffset,
            width: startPanelWidth,
            height: notchHeight
        )

        smallPanel = FocusablePanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        smallPanel.registerForDraggedTypes([.fileURL])

        smallPanel.title = "ComfyNotch"
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)  // sits under screenSaver
        smallPanel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        smallPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        smallPanel.isMovableByWindowBackground = false
        smallPanel.backgroundColor = .clear
        smallPanel.isOpaque = false
        smallPanel.hasShadow = false

        // Create and add widgets to the store

        let albumWidget = CompactAlbumWidget()
        let movingDotsWidget = MovingDotsView()
        let settingsWidget = SettingsButtonWidget()
        let fileTrayWidget = QuickAccessWidget()

        // Add Widgets to the WidgetStore
        compactWidgetStore.addWidget(albumWidget)
        compactWidgetStore.addWidget(movingDotsWidget)
        compactWidgetStore.addWidget(settingsWidget)
        compactWidgetStore.addWidget(fileTrayWidget)
        
        let contentView = ComfyNotchView()
            .environmentObject(compactWidgetStore)
            .environmentObject(expandedWidgetStore)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = panelRect  // ensure it's full size
        smallPanel.contentView = hostingView
        smallPanel.makeKeyAndOrderFront(nil)
    }
    
    public func applyOpeningLayout() {
        /// Opening Layout is just hiding every possible widget
        compactWidgetStore.hideWidget(named: "QuickAccessWidget")
        compactWidgetStore.hideWidget(named: "AlbumWidget")
        compactWidgetStore.hideWidget(named: "MovingDotsWidget")
        compactWidgetStore.hideWidget(named: "Settings")
        
        expandedWidgetStore.hideWidget(named: "MusicPlayerWidget")
        expandedWidgetStore.hideWidget(named: "TimeWidget")
        expandedWidgetStore.hideWidget(named: "NotesWidget")
        expandedWidgetStore.hideWidget(named: "CameraWidget")
        expandedWidgetStore.hideWidget(named: "AIChatWidget")
        expandedWidgetStore.hideWidget(named: "EventWidget")
    }
    public func applyExpandedWidgetLayout() {
        withAnimation(Anim.spring) {

            /// When the notch is expanded we want the top row to show the settings widget on the right
            /// But we wanna first hide any of the shown stuff
            compactWidgetStore.hideWidget(named: "MovingDotsWidget")
            compactWidgetStore.hideWidget(named: "AlbumWidget")
            compactWidgetStore.showWidget(named: "Settings")
            compactWidgetStore.showWidget(named: "QuickAccessWidget")
            
            /// Then we wanna show every possible widget cuz if its not added it wont actually show
            expandedWidgetStore.showWidget(named: "MusicPlayerWidget")
            expandedWidgetStore.showWidget(named: "TimeWidget")
            expandedWidgetStore.showWidget(named: "NotesWidget")
            expandedWidgetStore.showWidget(named: "CameraWidget")
            expandedWidgetStore.showWidget(named: "AIChatWidget")
            expandedWidgetStore.showWidget(named: "EventWidget")
        }
    }
    public func applyCompactWidgetLayout() {
        withAnimation(Anim.spring) {
            /// When the notch is closed we wanna show the compact album on the left, and dots on the right and hide
            /// The Settings Widget
            compactWidgetStore.hideWidget(named: "QuickAccessWidget")
            compactWidgetStore.hideWidget(named: "Settings")
            compactWidgetStore.showWidget(named: "AlbumWidget")
            compactWidgetStore.showWidget(named: "MovingDotsWidget")
            
            /// Then we hide every possible widget
            expandedWidgetStore.hideWidget(named: "MusicPlayerWidget")
            expandedWidgetStore.hideWidget(named: "TimeWidget")
            expandedWidgetStore.hideWidget(named: "NotesWidget")
            expandedWidgetStore.hideWidget(named: "CameraWidget")
            expandedWidgetStore.hideWidget(named: "AIChatWidget")
            expandedWidgetStore.hideWidget(named: "EventWidget")
        }
    }

    /// --Mark : Utility Methods
    private func displayCurrentBigPanelWidgets(with title: String = "Current Big Panel Widgets") {
        debugLog("=====================================================")
        debugLog("\(title)")
        debugLog("=====================================================")
        for widget in expandedWidgetStore.widgets {
            debugLog("Name: \(widget.widget.name), Visible: \(widget.isVisible)")
        }
        debugLog("=====================================================")
    }

    /**
     * Utility methods for widget management and panel dimensions.
     */
    func addWidgetToBigPanel(_ widget: Widget) {
        expandedWidgetStore.addWidget(widget)
    }

    func addWidgetsToSmallPanel(_ widget: Widget) {
    }

    func getNotchHeight() -> CGFloat {
        if let screen = DisplayManager.shared.selectedScreen {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.top
        }
        return 0
    }
}
