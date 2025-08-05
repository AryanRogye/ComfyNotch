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
        smallPanel.acceptsMouseMovedEvents = true
        
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
        
        
        compactWidgetStore.loadWidgets()
        
        self.logPanelFrame(reason: "Initialized Panel")
    }
    
    public func logPanelFrame(reason: String) {
        debugLog("""
        📐 \(reason):
           ⤷ MinX : \(smallPanel.frame.minX)
           ⤷ MinY : \(smallPanel.frame.minY)
           ⤷ MaxX : \(smallPanel.frame.maxX)
           ⤷ MaxY : \(smallPanel.frame.maxY)
           ⤷ Width  x Height : \(smallPanel.frame.width) x \(smallPanel.frame.height)
        """, from: .ui)
    }
    
    // MARK: - Layout Management
    
    /// Function to wipe EVERYTHING off the screen
    public func applyOpeningLayout() {
        DispatchQueue.main.async {
            /// Opening Layout is just hiding every possible widget
            self.compactWidgetStore.applyLayout(for: .empty)
            self.expandedWidgetStore.applyLayout(for: .empty)
        }
    }
    
    /// Function When Opening and want to show the Top Row
    public func applyExpandedWidgetLayout() {
        DispatchQueue.main.async {
            withAnimation(Anim.spring) {
                self.compactWidgetStore.applyLayout(for: .expanded)
                self.expandedWidgetStore.applyLayout(for: .expanded)
            }
        }
    }
    
    /// Function called when closing and not wanting to show the top row
    public func applyCompactWidgetLayout() {
        DispatchQueue.main.async {
            withAnimation(Anim.spring) {
                self.compactWidgetStore.applyLayout(for: .music)
                self.expandedWidgetStore.applyLayout(for: .music)
            }
        }
    }
    
    private var brightnessTimer: Timer?
    private var volumeTimer: Timer?
    
    private var isShowingBrightness: Bool = false
    private var isShowingVolume: Bool = false
    
    private func startVolumeTimer() {
        volumeTimer?.invalidate()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isShowingVolume = false

            if self.panelState == .closed {
                self.applyOpeningLayout()
                self.applyCompactWidgetLayout()
            }
        }
    }
    
    private func startBrightnessTimer() {
        brightnessTimer?.invalidate()
        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isShowingBrightness = false
            
            if self.panelState == .closed {
                self.applyOpeningLayout()
                self.applyCompactWidgetLayout()
            }
        }
    }
    
    public func applyVolumeLayout() {
        guard self.panelState == .closed else { return }
        
        if isShowingBrightness {
            brightnessTimer?.invalidate()
            isShowingBrightness = false
        }
        
        if isShowingVolume {
            startVolumeTimer()
            return
        }
        
        self.isShowingVolume = true
        self.applyOpeningLayout()
        
        DispatchQueue.main.async {
            withAnimation(Anim.spring) {
                self.compactWidgetStore.applyLayout(for: .volume)
                self.expandedWidgetStore.applyLayout(for: .volume)
            }
        }
        
        startVolumeTimer()
    }
    
    public func applyBrightnessLayout() {
        guard self.panelState == .closed else { return }
        
        if isShowingVolume {
            volumeTimer?.invalidate()
            isShowingVolume = false
        }
        
        if isShowingBrightness {
            startBrightnessTimer()
            return
        }
        
        self.isShowingBrightness = true
        self.applyOpeningLayout()
        
        DispatchQueue.main.async {
            withAnimation(Anim.spring) {
                self.compactWidgetStore.applyLayout(for: .brightness)
                self.expandedWidgetStore.applyLayout(for: .brightness)
            }
        }
        
        startBrightnessTimer()
    }
    
    
    // MARK: - Utility Methods
    public func displayCurrentBigPanelWidgets(with title: String = "Current Big Panel Widgets") {
        debugLog("=====================================================", from: .ui)
        debugLog("\(title)", from: .ui)
        debugLog("=====================================================", from: .ui)
        for widget in expandedWidgetStore.widgets {
            debugLog("Name: \(widget.widget.name), Visible: \(widget.isVisible)", from: .ui)
        }
        debugLog("=====================================================", from: .ui)
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

@objc class UIManagerBridge: NSObject, ObservableObject {
    @objc static let shared = UIManagerBridge()
    @Published var brightness: Float = 0
    
    @objc func triggerBrightnessLayout() {
        UIManager.shared.applyBrightnessLayout()
    }
    
    @objc func setBrightness(_ brightness: Float) {
        DispatchQueue.main.async {
            self.brightness = brightness
        }
    }
}
