import AppKit


class HoverHandler: NSObject {  // Note: Now inheriting from NSObject
    private weak var panel: NSPanel?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var lastHapticTime: TimeInterval = 0

    private let expansionFactor: CGFloat = 1.1  // How much to grow (e.g., 1.1 = 10% bigger)
    private let animationDuration: TimeInterval = 0.15 // Animation duration


    init(panel: NSPanel) {
        self.panel = panel
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
        
        // Get panel's frame in screen coordinates
        let panelFrame = panel.frame
        
        // Simple check if the mouse is inside the panel's frame
        if panelFrame.contains(mouseLocation) {
            
            let now = CACurrentMediaTime()
            if now - lastHapticTime > 0.2 {
                triggerHapticFeedback()
                // animatePanel(expand: true)
                lastHapticTime = now
            }
        } else {
            // Mouse is outside the panel
            // animatePanel(expand: false)
        }
    }

    private func animatePanel(expand: Bool) {
        guard let panel = panel else { return }

        let originalFrame = panel.frame
        let originalWidth = originalFrame.width
        let originalHeight = originalFrame.height

        // Calculate the new width and height
        let newWidth = expand ? originalWidth * expansionFactor : originalWidth / expansionFactor
        let newHeight = expand ? originalHeight * expansionFactor : originalHeight / expansionFactor

        // Adjust the origin to keep the panel centered during scaling
        let deltaX = (newWidth - originalWidth) / 2
        let deltaY = (newHeight - originalHeight) / 2

        // Adjust the origin to move it correctly without jumping away
        let newOrigin = CGPoint(x: originalFrame.origin.x - deltaX, y: originalFrame.origin.y - deltaY)

        let newFrame = NSRect(origin: newOrigin, size: CGSize(width: newWidth, height: newHeight))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.setFrame(newFrame, display: true, animate: true)
        }
    }

    private func triggerHapticFeedback() {
        let hapticManager = NSHapticFeedbackManager.defaultPerformer
        // Use a stronger haptic pattern
        hapticManager.perform(.levelChange, performanceTime: .now)
        // Or for even stronger feedback:
        hapticManager.perform(.generic, performanceTime: .now)
        // hapticManager.perform(.alignment, performanceTime: .now)
    }
    
    // MARK: - NSTrackingArea methods with correct signatures
    @objc func mouseEntered(with event: NSEvent) {
        print("Mouse entered view")
        triggerHapticFeedback()
    }
    
    @objc func mouseExited(with event: NSEvent) {
        print("Mouse exited view")
    }
}