import AppKit
import Combine

/** 
 *
 *  This file when started listens for two-finger scroll events 
 *  both globally (outside the app) and locally (inside the app).
 *
 *  Scroll gestures are used to resize the big panel, 
 *  adjusting its width and height based on user interactions.
 *
 */
class ScrollHandler {
    static let shared = ScrollHandler()

    var scrollPadding: CGFloat = 15

    // Panel Values
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 100

    var minPanelWidth: CGFloat = 320
    var maxPanelWidth: CGFloat = 700

    var smallPanelRect: NSRect?

    // Small padding to make the snapping feel more natural
    var snapPadding: CGFloat = 10
    var isSnapping: Bool = false

    // Determine final state based on thresholds
    let snapOpenThreshold: CGFloat = 0.9  // 90% open
    let snapClosedThreshold: CGFloat = 0.5 // 50% open

    var offset: CGFloat
    private var cancellables = Set<AnyCancellable>()

    // The initial height of the panel when the app starts
    private init() {
        let settings = SettingsModel.shared
        offset = settings.openStateYOffset

        if let panel = UIManager.shared.smallPanel {
            smallPanelRect = panel.frame
        }
    }

    /** 
     *
     *  This function starts the scroll manager, setting up event listeners
     *  This is the only thing that should be called from outside this class.
     *  to start listening, we sometimes need to call update functions
     *
    */
    func start() {
        let settings = SettingsModel.shared

        settings.$openStateYOffset
            .dropFirst() // Skip the initial emission
            .sink { [weak self] newValue in
                self?.offset = newValue
                print("Offset updated to: \(newValue)")
                self?.applyOffsetChange()
            }
            .store(in: &cancellables)

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

    /// Programmatically opens the panel fully
    func open() {
        guard let panel = UIManager.shared.bigPanel else { return }
        /// When Opening make sure that the small panel is closed
        UIManager.shared.hoverHandler?.collapsePanelIfExpanded()

        let targetHeight = maxPanelHeight
        let targetWidth = maxPanelWidth
        let screen = NSScreen.main!

        var panelFrame = panel.frame
        panelFrame.size.width = targetWidth
        panelFrame.size.height = targetHeight
        panelFrame.origin.y = screen.frame.height - targetHeight - UIManager.shared.startPanelYOffset - offset
        panelFrame.origin.x = (screen.frame.width - targetWidth) / 2

        animatePanelTransition(to: panelFrame)
        updatePanelState(for: targetHeight)
    }

    /// Programmatically closes the panel fully
    func close() {
        guard let panel = UIManager.shared.bigPanel else { return }

        let targetHeight = minPanelHeight
        let targetWidth = minPanelWidth
        let screen = NSScreen.main!

        var panelFrame = panel.frame
        panelFrame.size.width = targetWidth
        panelFrame.size.height = targetHeight
        panelFrame.origin.y =
            screen.frame.height - targetHeight - UIManager.shared.startPanelYOffset - 35

        panelFrame.origin.x = (screen.frame.width - targetWidth) / 2

        animatePanelTransition(to: panelFrame)
        updatePanelState(for: targetHeight)
    }

    /**
     *
     *   This Function handles haptic feedback for scroll events.
     *
     */
    private func handleScrollHaptics(_ event: NSEvent) {
        let hapticManager = NSHapticFeedbackManager.defaultPerformer

        let scrollSpeed = abs(event.scrollingDeltaY)

        if scrollSpeed > 5.0 { // Higher threshold = less frequent, softer feedback
            hapticManager.perform(.levelChange, performanceTime: .now)
        }
    }

    /**
     *
     *   This function checks if the mouse is within the panel region.
     *   It checks both the big panel and small panel regions.
     *
     */
    private func isMouseInPanelRegion() -> Bool {
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation

        // First check if mouse is in big panel area
        if let panel = UIManager.shared.bigPanel {
            // Create a detection area that extends from the panel's current position 
            // all the way to its maximum possible position plus padding
            var detectionArea = panel.frame

            // Adjust height to include the entire region the panel could occupy
            if UIManager.shared.panelState != .closed {
                // If panel is open or partially open, detection area should extend from
                // current position to max panel height
                let maxPossibleHeight = maxPanelHeight
                detectionArea.size.height = maxPossibleHeight

                // Adjust y position to account for panel potentially moving downward
                detectionArea.origin.y = min(
                    panel.frame.origin.y,
                    NSScreen.main!.frame.height - maxPanelHeight - UIManager.shared.startPanelYOffset - offset
                )
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
        if UIManager.shared.panelState == .closed, let smallPanel = UIManager.shared.smallPanel {
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

    /**
     *
     *   This function handles the two-finger scroll event.
     *   It adjusts the height and width of the panel based on the scroll delta.
     *   It also handles snapping to open or closed states based on thresholds.
     *
     */
    private func handleTwoFingerScroll(_ event: NSEvent) {
        // If we're already snapping, ignore further scroll events
        if isSnapping { return }

        guard let panel = UIManager.shared.bigPanel else { return }

        let scrollDeltaY = event.scrollingDeltaY

        let scrollThreshold: CGFloat = 1.0 // Increased to avoid tiny flickers
        // print("Scroll delta Y: \(scrollDeltaY)")

        // Use DispatchQueue to avoid blocking the main thread
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if scrollDeltaY > scrollThreshold {
                // Scrolling down (Close)
                // DispatchQueue.main.async {
                //     self?.open()
                //     return
                // }
            } else if scrollDeltaY < -scrollThreshold {
                // Scrolling up (Open)
                DispatchQueue.main.async {
                    self?.close()
                    return
                }
            }
        }

        let currentHeight = panel.frame.height
        let proposedHeight = currentHeight + scrollDeltaY
        let clampedHeight = max(minPanelHeight, min(maxPanelHeight, proposedHeight))

        // Compute ratio from 0 (closed) to 1 (open)
        let ratio = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)
        let newWidth = minPanelWidth + ratio * (maxPanelWidth - minPanelWidth)

        // TODO: Maybe add a directional change detection
        if event.phase == .changed {
            // Update instantly with no animation
            updatePanelSize(toHeight: clampedHeight, toWidth: newWidth, animated: false)
        } else if event.phase == .ended || event.phase == .cancelled {
            // Start snapping
            isSnapping = true

            if ratio >= snapOpenThreshold {
                animatePanelToState(open: true)
                updatePanelState(for: maxPanelHeight)
            } else if ratio <= snapClosedThreshold {
                animatePanelToState(open: false)
                updatePanelState(for: minPanelHeight)
            } else {
                // If in between, decide based on whether ratio is more or less than 0.5
                let shouldOpen = ratio > 0.5
                animatePanelToState(open: shouldOpen)
                updatePanelState(for: shouldOpen ? maxPanelHeight : minPanelHeight)
            }
        }
    }

    /**
     *
     *   This function updates the panel size to the new height and width.
     *   It also animates the change if specified. this function is called
     *   by handleTwoFingerScroll when the scroll event is in the .changed phase.
     *   this is cuz it needs to be called when any movement has occurred
     *   TODO: Maybe add a directional change detection
     *
     */
    private func updatePanelSize(toHeight newHeight: CGFloat, toWidth newWidth: CGFloat, animated: Bool) {
        guard let screen = NSScreen.main else { return }

        if let panel = UIManager.shared.bigPanel {
            var panelFrame = panel.frame
            // Adjust origin so the panel remains aligned relative to the screen
            panelFrame.origin.y =
                screen.frame.height - newHeight - UIManager.shared.startPanelYOffset - offset
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

    /**
    * Animate the panel to the target state (open or closed).
    * Adjusts the panel's frame size and position based on the desired state.
    */
    private func animatePanelToState(open: Bool) {
        guard let screen = NSScreen.main, let panel = UIManager.shared.bigPanel else { return }

        // Determine the target dimensions based on whether the panel is opening or closing
        let (targetWidth, targetHeight) = calculateTargetSize(isOpening: open)
        let targetPosition = calculateTargetPosition(width: targetWidth, height: targetHeight, screen: screen)

        // Create the target frame
        var targetFrame = panel.frame
        targetFrame.size = NSSize(width: targetWidth, height: targetHeight)
        targetFrame.origin = targetPosition

        // Animate the panel transition
        animatePanelTransition(to: targetFrame)
    }

    /**
    * Calculate the target size (width and height) based on the desired state.
    */
    private func calculateTargetSize(isOpening: Bool) -> (CGFloat, CGFloat) {
        let targetWidth = isOpening ? maxPanelWidth : minPanelWidth
        let targetHeight = isOpening ? maxPanelHeight : minPanelHeight
        return (targetWidth, targetHeight)
    }

    /**
    * Calculate the target position (origin point) of the panel based on the screen size.
    */
    private func calculateTargetPosition(width: CGFloat, height: CGFloat, screen: NSScreen) -> CGPoint {
        let xPosition = (screen.frame.width - width) / 2

        let yPosition: CGFloat
        if UIManager.shared.panelState == .closed {
            // When closed, use the default offset (35)
            yPosition = screen.frame.height - height - UIManager.shared.startPanelYOffset - 35
        } else {
            // When open or partially open, use the user-defined offset
            yPosition = screen.frame.height - height - UIManager.shared.startPanelYOffset - offset
        }

        return CGPoint(x: xPosition, y: yPosition)
    }

    /**
    * Perform the animation to transition the panel to the target frame.
    */
    private func animatePanelTransition(to targetFrame: NSRect) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.05
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            UIManager.shared.bigPanel?.animator().setFrame(targetFrame, display: true)
        }, completionHandler: {
            self.isSnapping = false
        })
    }

    /**
     *
     *   This function updates the panel state based on the current height.
     *   It determines whether the panel is open, closed, or partially open
     *   and updates the UI accordingly.
     *   
     *   This is Where anything that needs to be done when the panel is open or closed
     */
    public func updatePanelState(for height: CGFloat) {
        if height >= maxPanelHeight {
            UIManager.shared.panelState = .open

            // 🔽 Close the hover-triggered small panel before opening big one
            UIManager.shared.hoverHandler?.collapsePanelIfExpanded()

            UIManager.shared.showBigPanelWidgets()
            UIManager.shared.showSmallPanelSettingsWidget()
        } else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
            UIManager.shared.hideBigPanelWidgets()
            UIManager.shared.hideSmallPanelSettingsWidget()

            if let panel = UIManager.shared.bigPanel, let smallPanelFrame = smallPanelRect {
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
            UIManager.shared.panelState = .partiallyOpen
            UIManager.shared.showBigPanelWidgets()
            UIManager.shared.hideSmallPanelSettingsWidget()
        }
    }

    func applyOffsetChange() {
        guard let panel = UIManager.shared.bigPanel else { return }

        // Get the current frame of the panel
        var frame = panel.frame

        // Adjust the y-position using the new offset value only if the panel is not closed
        if let screen = NSScreen.main {
            if UIManager.shared.panelState != .closed {
                frame.origin.y = screen.frame.height - frame.height - UIManager.shared.startPanelYOffset - offset
            } else {
                // If the panel is closed, position it using its normal closed position logic
                frame.origin.y = screen.frame.height - frame.height - UIManager.shared.startPanelYOffset - 35
            }
        }

        // Update the panel position
        panel.setFrame(frame, display: true, animate: true)
    }
}
