import AppKit

class ScrollManager {
    static let shared = ScrollManager()

    var scrollPadding: CGFloat = 15

    // Panel Values
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 100

    var minPanelWidth: CGFloat = 300
    var maxPanelWidth: CGFloat = 650

    // TODO: Add a way to set these values in the UI
    var snapThreshold: CGFloat = 0.5 // The percentage of max height where snapping occurs
    var snapPadding: CGFloat = 10 // Small padding to make the snapping feel more natural


    private init() {}

    func start() {
        // Register for two-finger scroll events
        // Global monitor for events outside your app
        NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
            if self.isMouseInPanelRegion() {
                self.handleTwoFingerScroll(event)
            }
        }
    
        // Local monitor for events inside your app
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if self.isMouseInPanelRegion() {
                self.handleTwoFingerScroll(event)
            }
            self.handleScrollHaptics(event)
            return event
        }
    }

    private func handleScrollHaptics(_ event: NSEvent) -> Void {
        let hapticManager = NSHapticFeedbackManager.defaultPerformer

        let scrollSpeed = abs(event.scrollingDeltaY)
        
        if scrollSpeed > 5.0 { // Higher threshold = less frequent, softer feedback
            hapticManager.perform(.levelChange, performanceTime: .now)
        }
    }

    private func isMouseInPanelRegion() -> Bool {
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        if let panel = UIManager.shared.panel {
            // Create a simple rectangular detection area exactly matching the panel
            // plus some padding around all sides
            let paddedFrame = NSRect(
                x: panel.frame.origin.x - scrollPadding,
                y: panel.frame.origin.y - scrollPadding,
                width: panel.frame.width + (scrollPadding * 2),
                height: panel.frame.height + (scrollPadding * 2)
            )
        
            return paddedFrame.contains(mouseLocation)
        }
        return false
    }

    private func handleTwoFingerScroll(_ event: NSEvent) {
        guard let panel = UIManager.shared.panel else { return }

        // The direction of scrollDeltaY can be inverted by "Natural" scrolling settings.
        // If it feels backward, flip the sign:
        let scrollDeltaY = event.scrollingDeltaY
        // let scrollDeltaY = -event.scrollingDeltaY  // <-- If you need to invert

        // Current panel height
        let currentHeight = panel.frame.height
        // Proposed new height
        let newHeight = currentHeight + scrollDeltaY

        // Clamp the new height
        let clampedHeight = max(minPanelHeight, min(maxPanelHeight, newHeight))

        // Compute a ratio from 0.0 (closed) to 1.0 (open)
        let ratio = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)

        // Calculate new width proportionally
        let newWidth = minPanelWidth + ratio * (maxPanelWidth - minPanelWidth)

        // Snap thresholds
        let snapOpenThreshold: CGFloat = 0.8  // 80% open
        let snapClosedThreshold: CGFloat = 0.2 // 20% open

        // Check snapping
        if ratio >= snapOpenThreshold {
            // Snap to fully open
            updatePanelSize(toHeight: maxPanelHeight, toWidth: maxPanelWidth)
            updatePanelState(for: maxPanelHeight)
        } 
        else if ratio <= snapClosedThreshold {
            // Snap to fully closed
            updatePanelSize(toHeight: minPanelHeight, toWidth: minPanelWidth)
            updatePanelState(for: minPanelHeight)
        } 
        else {
            // Smoothly interpolate
            updatePanelSize(toHeight: clampedHeight, toWidth: newWidth)
            updatePanelState(for: clampedHeight)
        }
    }

    private func handleTwoFingerScroll_(_ event: NSEvent) {
        let scrollDeltaY = event.scrollingDeltaY

        if let panel = UIManager.shared.panel {
            // Calculate new height
            let newHeight = panel.frame.height + scrollDeltaY
            let clampedHeight = max(minPanelHeight, min(maxPanelHeight, newHeight))
    
            // Calculate new width proportionally to height change
            let heightPercentage = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)
            let newWidth = minPanelWidth + (heightPercentage * (maxPanelWidth - minPanelWidth))
            let clampedWidth = max(minPanelWidth, min(maxPanelWidth, newWidth))

            // SNAP HANDLING LOGIC

            // Update the panel's size smoothly
            updatePanelSize(toHeight: clampedHeight, toWidth: clampedWidth)
            updatePanelState(for: clampedHeight)
        }
    }


    private func updatePanelSize(toHeight newHeight: CGFloat, toWidth newWidth: CGFloat) {
        guard let screen = NSScreen.main else { return }

        if let panel = UIManager.shared.panel {
            var panelFrame = panel.frame
            panelFrame.origin.y = screen.frame.height - newHeight - 2
            panelFrame.size.height = newHeight
            panelFrame.size.width = newWidth
            panelFrame.origin.x = (screen.frame.width - newWidth) / 2

            panel.setFrame(panelFrame, display: true, animate: true)
        }
    }

    public func updatePanelState(for height: CGFloat) {
        if height >= maxPanelHeight {
            UIManager.shared.panel_state = .OPEN
            UIManager.shared.showWidgets()
        } else if height <= minPanelHeight {
            UIManager.shared.panel_state = .CLOSED
            UIManager.shared.hideWidgets()
        } else {
            UIManager.shared.panel_state = .PARTIALLY_OPEN
            UIManager.shared.showWidgets()
        }
    }
}