import AppKit
import Combine

class ScrollHandler {
    static let shared = ScrollHandler()

    // MARK: – Configuration
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 100
    var minPanelWidth: CGFloat = 320
    var maxPanelWidth: CGFloat = 700

    private let maxPullDistance = 100
    /// Fine‑tune this multiplier to taste
    private let scrollSensitivity: CGFloat = 0.3
    private var panAccumulated: CGFloat = 0
    private var isSnapping = false


    private var cancellables = Set<AnyCancellable>()

    private init() {}

    /// MARK: – Public API

    /// Handle Pan is what the view will call when a pan gesture is made
    func handlePan(delta: CGFloat, phase: NSEvent.Phase) {
        guard !isSnapping else {
            // If user starts a new gesture during snap, cancel snap and reset accumulation
            if phase == .began {
                /// Stop existing animation
                if let panel = UIManager.shared.smallPanel {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0
                        panel.animator().setFrame(panel.frame, display: true)
                    }
                }
                isSnapping = false
                panAccumulated = delta
                // Process the first part of the new gesture
                process(delta: panAccumulated, phase: .changed)
            } else if phase == .changed || phase == .ended || phase == .cancelled {
                // Ignore further events from the *previous* gesture if snapping
                return
            } else {
                // Reset if phase is weird while snapping
                panAccumulated = 0
            }
            return
        }


        panAccumulated += delta

        switch phase {
        case .began:
            process(delta: panAccumulated, phase: .began)
        case .changed:
            process(delta: panAccumulated, phase: .changed)
        case .ended, .cancelled:
            process(delta: panAccumulated, phase: phase)
            panAccumulated = 0 // reset for next gesture
        default:
            break
        }
    }

    /// This animation makes sure that it just "expands"
    func openFull() {
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        isSnapping = true

        let screen = NSScreen.main!                // full screen coords
        let finalHeight = minPanelHeight + CGFloat(maxPullDistance)
        let finalWidth  = maxPanelWidth
        let finalX      = (screen.frame.width - finalWidth) / 2
        let finalY      = screen.frame.height
        - finalHeight
        - UIManager.shared.startPanelYOffset

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(
                NSRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight),
                display: true
            )
        }, completionHandler: {
                self.isSnapping = false
                self.updateState(for: finalHeight)
                UIManager.shared.panelState = .open
            })
    }

    func closeFull() {
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        isSnapping = true

        // 1) compute the exact final closed frame
        let screen      = NSScreen.main!
        let finalHeight = minPanelHeight
        let finalWidth  = minPanelWidth
        let finalX      = (screen.frame.width - finalWidth) / 2
        let finalY      = screen.frame.height
        - finalHeight
        - UIManager.shared.startPanelYOffset

        let finalFrame = NSRect(
            x: finalX,
            y: finalY,
            width: finalWidth,
            height: finalHeight
        )

        // 2) animate there
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(finalFrame, display: true)
        }, completionHandler: {
                // 3a) immediately snap the layer to the exact frame (no animations)
                panel.setFrame(finalFrame, display: true)

                // 3b) update your model/state flags
                self.isSnapping = false
                self.updateState(for: finalHeight)
                UIManager.shared.panelState = .closed

                // 3c) collapse SwiftUI bottom section
                PanelAnimationState.shared.isExpanded = false
                PanelAnimationState.shared.bottomSectionHeight = 0
            })
    }

    private func snapCloseHeight(
        finalX: CGFloat,
        finalY: CGFloat,
        finalWidth: CGFloat,
        finalHeight: CGFloat
    ) {
        guard let panel = UIManager.shared.smallPanel else {
            isSnapping = false
            return
        }

        let screen = NSScreen.main!                // full screen coords
        let frame = NSRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(frame, display: true)
        }, completionHandler: {
                self.isSnapping = false
                self.updateState(for: finalHeight)
                UIManager.shared.panelState = .closed
            })
    }

    // MARK: – Internals

    /// Function that does the animations
    private func process(delta: CGFloat, phase: NSEvent.Phase) {
        guard let panel = UIManager.shared.smallPanel else { return }

        // Make sure panel is ready on first interaction
        if phase == .began && !panel.isVisible {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        }

        switch phase {
        case .began, .changed: // Handle direct manipulation for began and changed
            // Calculate the target frame based on the accumulated drag delta
            if let targetFrame = calculateInteractiveFrame(for: delta) {
                // Directly set the frame for immediate feedback
                panel.setFrame(targetFrame, display: true)
                // Optionally update the state continuously
                // updateState(for: targetFrame.height)
            }

        case .ended, .cancelled:
            // Gesture finished, decide whether to snap open or closed
            decideSnapAnimation(basedOnDelta: delta)

        default:
            break
        }
    }

    /// Calculates the target frame based on the interactive drag delta.
    /// - Parameter delta: The accumulated scroll/pan delta (raw value).
    /// - Returns: The calculated NSRect for the panel, or nil if panel doesn't exist.
    private func calculateInteractiveFrame(for delta: CGFloat) -> NSRect? {
        guard let panel = UIManager.shared.smallPanel else { return nil }
        let screen = NSScreen.main!

        var frame = panel.frame // Start with the current frame

        // Clamp adjustment: Allow pulling down up to maxPullDistance + buffer, and pulling up without limit initially
        // We'll rely on height clamping later to prevent negative height.
        // Let's rethink the clamping: we want to clamp the *effect* on height/width.

        // Calculate base Y position for the minimum height panel
        let baseWidthX = (screen.frame.width - minPanelWidth) / 2

        // --- Calculate Target Height ---
        let rawPull = delta
        var targetHeight = minPanelHeight + rawPull

        // Clamp height: Can't be smaller than minimum, can't be larger than max pull dictates
        targetHeight = max(minPanelHeight, targetHeight)
        targetHeight = min(minPanelHeight + CGFloat(maxPullDistance), targetHeight) // Max height during this phase

        // --- Calculate Target Width ---
        var targetWidth = minPanelWidth
        var targetX = baseWidthX

        // Check if we've pulled *beyond* the max distance for height expansion
        let pullBeyondHeightMax = (delta * scrollSensitivity) - CGFloat(maxPullDistance)
        if pullBeyondHeightMax > 0 {
            // Expand width based on how far beyond maxPullDistance we are
            let widthExpansionBuffer: CGFloat = 100 // How much extra pull expands width fully
            let widthRatio = min(max(0, pullBeyondHeightMax / widthExpansionBuffer), 1.0) // Clamp ratio 0..1
            targetWidth = minPanelWidth + widthRatio * (maxPanelWidth - minPanelWidth)
            targetX = (screen.visibleFrame.width - targetWidth) / 2 + screen.visibleFrame.origin.x
        }

        // --- Calculate Target Y Origin ---
        // Y origin depends on the calculated height
        let targetY = screen.frame.height
        - targetHeight
        - UIManager.shared.startPanelYOffset

        // --- Construct Final Frame ---
        frame.origin.x = targetX
        frame.origin.y = targetY
        frame.size.width = targetWidth
        frame.size.height = targetHeight

        return frame
    }

    /// Decides whether to snap open or closed based on the final drag delta.
    private func decideSnapAnimation(basedOnDelta delta: CGFloat) {
        guard !isSnapping else { return } // Don't start a new snap if already snapping

        // Use the *raw* accumulated delta to check against the threshold
        let threshold: CGFloat = CGFloat(maxPullDistance) * 0.6 // 60% of the distance needed to *start* width expansion

        if delta >= threshold {
            openFull() // Snap fully open
        } else {
            closeFull() // Snap fully closed
        }
    }

    private func updateState(for height: CGFloat) {
        let open = (height >= maxPanelHeight)
        // 1️⃣ drive SwiftUI:
        PanelAnimationState.shared.isExpanded = open
        PanelAnimationState.shared.bottomSectionHeight = open
            ? (height - minPanelHeight)
            : 0

        // 2️⃣ keep your existing panel‑store logic:
        if open {
            UIManager.shared.panelState = .open
            UIManager.shared.showBigPanelWidgets()
            UIManager.shared.showSmallPanelSettingsWidget()
        } else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
            UIManager.shared.hideBigPanelWidgets()
            UIManager.shared.hideSmallPanelSettingsWidget()
        } else {
            UIManager.shared.panelState = .partiallyOpen
            UIManager.shared.showBigPanelWidgets()
            UIManager.shared.hideSmallPanelSettingsWidget()
        }
    }

    // MARK: – Helpers
}
