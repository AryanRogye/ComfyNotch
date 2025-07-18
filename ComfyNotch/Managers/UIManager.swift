import AppKit
import SwiftUI
import CoreGraphics

/**
 * Represents the current state of the panel display, this is used
 * everwhere to determine how the notch should behave, you can search for
 * panelState in the codebase to see how it is used
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
 * UIManager handles the core Notch Window.
 * Responsible for managing panels, widget stores, and panel states.
 *
 * Key Components:
 * - smallPanel: Displays compact widgets in the notch area
 * - Widget Stores: Manages widget collections for both panels
 */
class UIManager: ObservableObject {
    static let shared = UIManager()
    
    // MARK: - Stores
    let compactWidgetStore = CompactWidgetsStore()
    let expandedWidgetStore = ExpandedWidgetsStore()
    
    
    // MARK: - Main Panel Components
    var smallPanel: NSPanel!
    
    @Published var panelState: PanelState = .closed
    
    var startPanelHeight: CGFloat = 0
    var startPanelWidth: CGFloat = 300
    
    // TODO: look into this if it is really needed
    var startPanelYOffset: CGFloat = 0
    
    /**
     * Initializes the UI manager and sets up initial dimensions.
     * Configures panel height based on notch size and initializes audio components.
     */
    private init() {
        startPanelHeight = getNotchHeight()
        AudioManager.shared.getNowPlayingInfo() { _ in }
    }
    
    /**
     * Sets up both small and big panels with their initial configurations.
     */
    func start() {
        setupSmallPanel()
    }
    
    // MARK: - Construction
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
        /// Allow content to draw outside panel bounds
        smallPanel.contentView?.wantsLayer = true
        
        smallPanel.registerForDraggedTypes([.fileURL])
        smallPanel.title = "ComfyNotch"
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        smallPanel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        smallPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        smallPanel.isMovableByWindowBackground = false
        smallPanel.backgroundColor = .clear
        smallPanel.isOpaque = false
        smallPanel.hasShadow = false
        
        
        let contentView = ComfyNotchView()
            .environmentObject(compactWidgetStore)
            .environmentObject(expandedWidgetStore)
        
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = panelRect
        
        /// Allow hosting view to overflow
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = false
        
        smallPanel.contentView = hostingView
        smallPanel.makeKeyAndOrderFront(nil)
        
        self.loadWidgets()
    }
    
    // MARK: - Widget Loading
    /// NOTE: this is only called once at the start but it could be rlly weird if battery is low
    private func loadWidgets() {
        /// Strategy for widget loading, to avoid cpu spikes and UI Lag
        let widgets: [(String, () -> Widget, Bool)] = [
            ("Settings", { SettingsButtonWidget() }, false),      // Lightweight first
            ("MovingDots", { MovingDotsView() }, false),         // Visual feedback
            ("FileTray", { QuickAccessWidget() }, true),         // Medium weight
            ("Album", { CompactAlbumWidget() }, true)            // Heaviest last
        ]
        
        var index = 0;
        
        func loadNextWidget() {
            guard index < widgets.count else { return }
            let (_, widgetCreator, isHeavy) = widgets[index]
            index += 1
            
            let qos: DispatchQoS.QoSClass = isHeavy ? .background : .utility
            let delay: TimeInterval = isHeavy ? 0.3 : 0.1
            
            DispatchQueue.global(qos: qos).async {
                let widget = widgetCreator()
                
                DispatchQueue.main.async {
                    self.compactWidgetStore.addWidget(widget)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        loadNextWidget()
                    }
                }
            }
        }
        
        // Start loading after UI is settled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            loadNextWidget()
        }
    }
    
    // MARK: - Layout Management
    
    /// Function to wipe EVERYTHING off the screen
    public func applyOpeningLayout() {
        DispatchQueue.main.async {
            /// Opening Layout is just hiding every possible widget
            self.compactWidgetStore.hideWidget(named: "QuickAccessWidget")
            self.compactWidgetStore.hideWidget(named: "AlbumWidget")
            self.compactWidgetStore.hideWidget(named: "MovingDotsWidget")
            self.compactWidgetStore.hideWidget(named: "Settings")
            
            self.expandedWidgetStore.hideWidget(named: "MusicPlayerWidget")
            self.expandedWidgetStore.hideWidget(named: "TimeWidget")
            self.expandedWidgetStore.hideWidget(named: "NotesWidget")
            self.expandedWidgetStore.hideWidget(named: "CameraWidget")
            self.expandedWidgetStore.hideWidget(named: "AIChatWidget")
            self.expandedWidgetStore.hideWidget(named: "EventWidget")
        }
    }
    
    /// Function When Opening and want to show the Top Row
    public func applyExpandedWidgetLayout() {
        DispatchQueue.main.async {
            withAnimation(Anim.spring) {
                /// When the notch is expanded we want the top row to show the settings widget on the right
                /// But we wanna first hide any of the shown stuff
                self.compactWidgetStore.hideWidget(named: "MovingDotsWidget")
                self.compactWidgetStore.hideWidget(named: "AlbumWidget")
                self.compactWidgetStore.showWidget(named: "Settings")
                self.compactWidgetStore.showWidget(named: "QuickAccessWidget")
                
                // Then we wanna show every possible widget cuz if its not added it wont actually show
                self.expandedWidgetStore.showWidget(named: "MusicPlayerWidget")
                self.expandedWidgetStore.showWidget(named: "TimeWidget")
                self.expandedWidgetStore.showWidget(named: "NotesWidget")
                self.expandedWidgetStore.showWidget(named: "CameraWidget")
                self.expandedWidgetStore.showWidget(named: "AIChatWidget")
                self.expandedWidgetStore.showWidget(named: "EventWidget")
            }
        }
    }
    
    /// Function called when closing and not wanting to show the top row
    public func applyCompactWidgetLayout() {
        /// When the notch is closed we wanna show the compact album on the left, and dots on the right and hide
        /// The Settings Widget
        DispatchQueue.main.async {
            withAnimation(Anim.spring) {
                self.compactWidgetStore.hideWidget(named: "QuickAccessWidget")
                self.compactWidgetStore.hideWidget(named: "Settings")
                self.compactWidgetStore.showWidget(named: "AlbumWidget")
                self.compactWidgetStore.showWidget(named: "MovingDotsWidget")
                
                /// Then we hide every possible widget
                self.expandedWidgetStore.hideWidget(named: "MusicPlayerWidget")
                self.expandedWidgetStore.hideWidget(named: "TimeWidget")
                self.expandedWidgetStore.hideWidget(named: "NotesWidget")
                self.expandedWidgetStore.hideWidget(named: "CameraWidget")
                self.expandedWidgetStore.hideWidget(named: "AIChatWidget")
                self.expandedWidgetStore.hideWidget(named: "EventWidget")
            }
        }
    }
    
    // MARK: - Utility Methods
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
    
    func getNotchHeight() -> CGFloat {
        if let screen = DisplayManager.shared.selectedScreen {
            let safeAreaInsets = screen.safeAreaInsets
            let calculatedHeight = safeAreaInsets.top
            
            /// Only return calculated height if it is greater than 0
            if calculatedHeight > 0 {
                return calculatedHeight
            }
        }
        
        /// If no screen is selected or height is 0, return fallback height
        let fallbackHeight = SettingsModel.shared.notchMinFallbackHeight
        
        /// Make sure fallback height is greater than 0 or go to the fallback 40
        return fallbackHeight > 0 ? fallbackHeight : 40
    }
}
