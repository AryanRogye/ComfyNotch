import AppKit

enum HoverState {
    case HOVERING
    case NOT_HOVERING
}
class HoverHandler: NSObject {  // Note: Now inheriting from NSObject
    private weak var panel: NSPanel?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var lastHapticTime: TimeInterval = 0

    private let expansionFactor: CGFloat = 1.5  // How much to grow (e.g., 1.1 = 10% bigger)
    private let animationDuration: TimeInterval = 0.2 // Animation duration

    private var originalFrame: NSRect
    private var originalWidth: CGFloat
    private var originalHeight: CGFloat

    private var expandedWidth : CGFloat
    private var expandedHeight : CGFloat

    private var collapseTimer: Timer?
    private var isUsingHapticFeedback: Bool = false
    
    // Start with no hover state
    var hoverState : HoverState = .NOT_HOVERING

    init(panel: NSPanel) {
        self.panel = panel
        // set original frame
        self.originalFrame = panel.frame
        self.originalWidth = originalFrame.width
        self.originalHeight = originalFrame.height

        // claculate the maximum possible width and height for the panel
        self.expandedWidth = originalWidth
        self.expandedHeight = originalHeight * expansionFactor

        super.init() // Important: call super.init() after setting properties but before other setup
        startListeningForMouseMoves()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startListeningForMouseMoves() {
        // Local monitor for events in our application
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
        
        // Global monitor for events outside our application
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
        }
        
        // Also add tracking area to the panel's content view
        if let contentView = panel?.contentView {
            let trackingArea = NSTrackingArea(
                rect: contentView.bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
                owner: self,
                userInfo: nil
            )
            contentView.addTrackingArea(trackingArea)
        }
    }
    
    private func stopMonitoring() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
    
    private func handleMouseMoved(_ event: NSEvent) {
        guard let panel = panel else { return }

        // We need to convert the screen coordinates properly
        let mouseLocation = NSEvent.mouseLocation

        // 🧠 Padding zone in pixels
        let padding: CGFloat = 10
        let closingPadding : CGFloat = 50
        
        // Get panel's frame in screen coordinates
        let panelFrame = panel.frame.insetBy(dx: -padding, dy: -padding)
        let openedPanelFrameWithPadding = panel.frame.insetBy(dx: -closingPadding, dy: -closingPadding)
        
        // Simple check if the mouse is inside the panel's frame
        if panelFrame.contains(mouseLocation) {
            // Inside padding area

            // Cancel any pending collapse
            collapseTimer?.invalidate()
            collapseTimer = nil

            if UIManager.shared.panel_state == .CLOSED {
                let now = CACurrentMediaTime()
                if now - lastHapticTime > 0.2 {
                    triggerHapticFeedback()
                    animatePanel(expand: true)
                    lastHapticTime = now
                }
            }

            hoverState = .HOVERING
        } else if !openedPanelFrameWithPadding.contains(mouseLocation) {  
            // 🔴 Mouse is outside padded area
            // Don't double up timers
            if collapseTimer == nil {
                collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    guard let self else { return }

                    if UIManager.shared.panel_state == .CLOSED || UIManager.shared.panel_state == .OPEN {
                        self.animatePanel(expand: false)
                        self.hoverState = .NOT_HOVERING
                    }

                    self.collapseTimer = nil
                    // Reset haptic feedback state
                    self.isUsingHapticFeedback = false
                }
            }
        }
    }

    private func triggerHapticFeedback() {
        if isUsingHapticFeedback {
            return
        }
        let hapticManager = NSHapticFeedbackManager.defaultPerformer
        // Use a stronger haptic pattern
        hapticManager.perform(.levelChange, performanceTime: .now)
        // Or for even stronger feedback:
        hapticManager.perform(.generic, performanceTime: .now)
        // hapticManager.perform(.alignment, performanceTime: .now)
        self.isUsingHapticFeedback = true
    }
    
    // MARK: - NSTrackingArea methods with correct signatures
    @objc func mouseEntered(with event: NSEvent) {
        print("Mouse entered view")
        triggerHapticFeedback()
    }
    
    @objc func mouseExited(with event: NSEvent) {
        print("Mouse exited view")
    }

    private func animatePanel(expand: Bool) {

        guard let panel = self.panel else { return }

        PanelAnimationState.shared.isExpanded = expand
        if expand {
            PanelAnimationState.shared.bottomSectionHeight = self.expandedHeight
        } else {
            PanelAnimationState.shared.bottomSectionHeight = 0

            // 2. Shrink panel a tiny moment later
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let collapsedFrame = NSRect(
                    x: self.originalFrame.origin.x,
                    y: self.originalFrame.origin.y,
                    width: self.originalWidth,
                    height: self.originalHeight
                )

                NSAnimationContext.runAnimationGroup { context in
                    context.duration = self.animationDuration
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    panel.animator().setFrame(collapsedFrame, display: true)
                }
            }
    }
        
//
//        // Calculate the new width and height
//
//        let newWidth = expand ? expandedWidth : originalWidth
//        let newHeight = expand ? expandedHeight : originalHeight
//
//        // Adjust the origin to keep the panel centered during scaling
//        let deltaX = (newWidth - originalWidth) / 2
//        let deltaY = (newHeight - originalHeight) / 2
//
//        // Adjust the origin to move it correctly without jumping away
//        // let newOrigin = CGPoint(x: originalFrame.origin.x - deltaX, y: originalFrame.origin.y - deltaY)
//        let newOrigin = CGPoint(
//            x: round(originalFrame.origin.x - deltaX),
//            y: round(originalFrame.origin.y - deltaY)
//        )
//        // let originalOrigin = originalFrame.origin
//        let newFrame = NSRect(origin: newOrigin, size: CGSize(width: newWidth, height: newHeight))
//
//        NSAnimationContext.runAnimationGroup { context in
//            context.duration = animationDuration
//            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.3, 1.0, 0.7, 1.0)
//            panel.animator().setFrame(newFrame, display: true)
//        }
    }
}
