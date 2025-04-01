import AppKit

class ScrollManager {
    static let shared = ScrollManager()

    var scrollPadding: CGFloat = 15

    // Panel Values
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 100

    var minPanelWidth: CGFloat = 300
    var maxPanelWidth: CGFloat = 650

    var smallPanelRect: NSRect?  // Store the position and size of the small panel

    // TODO: Add a way to set these values in the UI
    var snapThreshold: CGFloat = 0.1 // The percentage of max height where snapping occurs
    var snapPadding: CGFloat = 10 // Small padding to make the snapping feel more natural
    var isSnapping: Bool = false



    private init() {
        if let panel = UIManager.shared.small_panel {
            smallPanelRect = panel.frame  // Store the initial position of the small panel
        }
    }

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
        
        // First check if mouse is in big panel area
        if let panel = UIManager.shared.big_panel {
            // Create a detection area that extends from the panel's current position 
            // all the way to its maximum possible position plus padding
            var detectionArea = panel.frame
            
            // Adjust height to include the entire region the panel could occupy
            if UIManager.shared.panel_state != .CLOSED {
                // If panel is open or partially open, detection area should extend from
                // current position to max panel height
                let maxPossibleHeight = maxPanelHeight
                detectionArea.size.height = maxPossibleHeight
                
                // Adjust y position to account for panel potentially moving downward
                detectionArea.origin.y = min(panel.frame.origin.y, 
                                            NSScreen.main!.frame.height - maxPanelHeight - UIManager.shared.startPanelYOffset - 35)
            }
            
            // Add padding around all sides
            detectionArea = NSRect(
                x: detectionArea.origin.x - scrollPadding,
                y: detectionArea.origin.y - scrollPadding,
                width: detectionArea.width + (scrollPadding * 2),
                height: detectionArea.height + (scrollPadding * 2)
            )
            
            if detectionArea.contains(mouseLocation) {
                return true
            }
        }
        
        // Also check small panel if it's visible
        if UIManager.shared.panel_state == .CLOSED, let smallPanel = UIManager.shared.small_panel {
            let paddedFrame = NSRect(
                x: smallPanel.frame.origin.x - scrollPadding,
                y: smallPanel.frame.origin.y - scrollPadding,
                width: smallPanel.frame.width + (scrollPadding * 2),
                height: smallPanel.frame.height + (scrollPadding * 2)
            )
            
            return paddedFrame.contains(mouseLocation)
        }
        
        return false
    }

    private func handleTwoFingerScroll(_ event: NSEvent) {
        // If we're already snapping, ignore further scroll events
        if isSnapping { return }

        guard let panel = UIManager.shared.big_panel else {
            print("Big panel is nil. Make sure it's initialized before using it.")
            return
        }
        
        let scrollDeltaY = event.scrollingDeltaY
        let currentHeight = panel.frame.height
        let proposedHeight = currentHeight + scrollDeltaY
        let clampedHeight = max(minPanelHeight, min(maxPanelHeight, proposedHeight))
        
        // Compute ratio from 0 (closed) to 1 (open)
        let ratio = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)
        let newWidth = minPanelWidth + ratio * (maxPanelWidth - minPanelWidth)
        
        if event.phase == .changed {
            // Update instantly with no animation
            updatePanelSize(toHeight: clampedHeight, toWidth: newWidth, animated: false)
        }
        else if event.phase == .ended || event.phase == .cancelled {
            // Determine final state based on thresholds
            let snapOpenThreshold: CGFloat = 0.8  // 80% open
            let snapClosedThreshold: CGFloat = 0.2 // 20% open
            
            // Start snapping
            isSnapping = true
            
            if ratio >= snapOpenThreshold {
                animatePanelToState(open: true)
                updatePanelState(for: maxPanelHeight)
            }
            else if ratio <= snapClosedThreshold {
                animatePanelToState(open: false)
                updatePanelState(for: minPanelHeight)
            }
            else {
                // If in between, decide based on whether ratio is more or less than 0.5
                let shouldOpen = ratio > 0.5
                animatePanelToState(open: shouldOpen)
                updatePanelState(for: shouldOpen ? maxPanelHeight : minPanelHeight)
            }
        }
    }

    private func updatePanelSize(toHeight newHeight: CGFloat, toWidth newWidth: CGFloat, animated: Bool) {
        guard let screen = NSScreen.main else { return }
        
        if let panel = UIManager.shared.big_panel {
            var panelFrame = panel.frame
            // Adjust origin so the panel remains aligned relative to the screen
            panelFrame.origin.y = screen.frame.height - newHeight - UIManager.shared.startPanelYOffset - 35  // Adjust offset as needed
            panelFrame.size.height = newHeight
            panelFrame.size.width = newWidth
            panelFrame.origin.x = (screen.frame.width - newWidth) / 2
            
            if animated {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3  // tweak duration as desired
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    panel.animator().setFrame(panelFrame, display: true)
                })
            } else {
                panel.setFrame(panelFrame, display: true, animate: false)
            }
        }
    }

    private func animatePanelToState(open: Bool) {
        guard let screen = NSScreen.main, let panel = UIManager.shared.big_panel else { return }
        let targetHeight = open ? maxPanelHeight : minPanelHeight
        let targetWidth = open ? maxPanelWidth : minPanelWidth
        var targetFrame = panel.frame
        targetFrame.size.height = targetHeight
        targetFrame.size.width = targetWidth
        targetFrame.origin.y = screen.frame.height - targetHeight - UIManager.shared.startPanelYOffset - 35  // Adjust offset as needed
        targetFrame.origin.x = (screen.frame.width - targetWidth) / 2
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetFrame, display: true)
        }, completionHandler: {
            // Reset snapping flag when animation completes
            self.isSnapping = false
        })
    }

    public func updatePanelState(for height: CGFloat) {
        if height >= maxPanelHeight {
            UIManager.shared.panel_state = .OPEN
            UIManager.shared.showBigPanelWidgets()
            UIManager.shared.showSmallPanelSettingsWidget()
        } else if height <= minPanelHeight {
            UIManager.shared.panel_state = .CLOSED
            UIManager.shared.hideBigPanelWidgets()
            UIManager.shared.hideSmallPanelSettingsWidget()
            
            if let panel = UIManager.shared.big_panel, let smallPanelFrame = smallPanelRect {
                // Animate back to the small panel's frame (without extra offset)
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    panel.animator().setFrame(smallPanelFrame, display: true)
                }, completionHandler: {
                    self.isSnapping = false
                })
            }
        } else {
            UIManager.shared.panel_state = .PARTIALLY_OPEN
            UIManager.shared.showBigPanelWidgets()
            UIManager.shared.hideSmallPanelSettingsWidget()
        }
    }

    // Older version of handleTwoFingerScroll ( No Snap Handling )
    // private func handleTwoFingerScroll_(_ event: NSEvent) {
    //     let scrollDeltaY = event.scrollingDeltaY

    //     if let panel = UIManager.shared.panel {
    //         // Calculate new height
    //         let newHeight = panel.frame.height + scrollDeltaY
    //         let clampedHeight = max(minPanelHeight, min(maxPanelHeight, newHeight))
    
    //         // Calculate new width proportionally to height change
    //         let heightPercentage = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)
    //         let newWidth = minPanelWidth + (heightPercentage * (maxPanelWidth - minPanelWidth))
    //         let clampedWidth = max(minPanelWidth, min(maxPanelWidth, newWidth))

    //         // SNAP HANDLING LOGIC

    //         // Update the panel's size smoothly
    //         updatePanelSize(toHeight: clampedHeight, toWidth: clampedWidth)
    //         updatePanelState(for: clampedHeight)
    //     }
    // }
}