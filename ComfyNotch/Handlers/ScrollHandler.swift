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

    // MARK: – Public API

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

        let current = panel.frame
        let screen  = NSScreen.main!

        // 1) true final
        let trueH     = minPanelHeight + CGFloat(maxPullDistance)
        let finalW    = maxPanelWidth
        let dx        = finalW - current.width
        let x         = current.origin.x - dx/2
        let trueY     = screen.frame.height - trueH
        let trueFrame = NSRect(x: x, y: trueY, width: finalW, height: trueH)

        // 2) bigger overshoot (flowier)
        let overshootAmount: CGFloat = 0   // ↑ more stretch
        let overH     = trueH + overshootAmount
        let overY     = screen.frame.height - overH
        let overFrame = NSRect(x: x, y: overY, width: finalW, height: overH)

        // 3) super‑springy curves
        let diveDur: TimeInterval = 0.25
        let recoDur: TimeInterval = 0.2
        let diveFn   = CAMediaTimingFunction(controlPoints: 0.2, 1.2, 0.4, 1.0)
        let recoFn   = CAMediaTimingFunction(controlPoints: 0.6, 1.8, 0.4, 1.0)

        // STEP A: stretch past
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration       = diveDur
            ctx.timingFunction = diveFn
            panel.animator().setFrame(overFrame, display: true)
        }) {
                // STEP B: recoil into place
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration       = recoDur
                    ctx.timingFunction = recoFn
                    panel.animator().setFrame(trueFrame, display: true)
                }) {
                        panel.setFrame(trueFrame, display: true)
                        self.isSnapping = false
                        self.updateState(for: trueH)
                        UIManager.shared.panelState = .open
                    }
            }
    }

    func closeFull() {
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        isSnapping = true
        
        let screen       = NSScreen.main!
        let startYOffset = UIManager.shared.startPanelYOffset
        
        // 1) fixed center‑of‑screen X
        let finalWidth = minPanelWidth
        let centerX    = (screen.frame.width - finalWidth) / 2
        
        // 2) true final closed frame
        let finalHeight   = minPanelHeight
        let trueFinalY    = screen.frame.height - finalHeight - startYOffset
        let trueFinalFrame = NSRect(
            x: centerX,
            y: trueFinalY,
            width: finalWidth,
            height: finalHeight
        )
        
        // 3) undershoot ‑ go a bit *below* the min height
        let undershoot: CGFloat = 20
        let underHeight = finalHeight - undershoot
        let underY      = screen.frame.height - underHeight - startYOffset
        let undershootFrame = NSRect(
            x: centerX,
            y: underY,
            width: finalWidth,
            height: underHeight
        )
        
        // 4) collapse your SwiftUI bottom section first
        PanelAnimationState.shared.isExpanded         = false
        PanelAnimationState.shared.bottomSectionHeight = 0
        
        // 5) timing & curves
        let diveDuration   : TimeInterval = 0.2
        let recoilDuration : TimeInterval = 0.15
        let diveCurve      = CAMediaTimingFunction(controlPoints: 0.65, 1.0, 0.5, 1.0)
        let recoilCurve    = CAMediaTimingFunction(controlPoints: 0.75, 1.0, 0.8, 1.0)
        
        // STEP A: animate *down* into undershoot
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration       = diveDuration
            ctx.timingFunction = diveCurve
            panel.animator().setFrame(undershootFrame, display: true)
        }, completionHandler: {
            // STEP B: animate *up* into true final
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration       = recoilDuration
                ctx.timingFunction = recoilCurve
                panel.animator().setFrame(trueFinalFrame, display: true)
            }, completionHandler: {
                // cleanup & state
                panel.setFrame(trueFinalFrame, display: true)
                self.isSnapping = false
                self.updateState(for: finalHeight)
                UIManager.shared.panelState = .closed
            })
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
            print("Opening")
            UIManager.shared.applyExpandedWidgetLayout()
        } else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
            print("Closed")
            UIManager.shared.applyCompactWidgetLayout()
        } else {
            UIManager.shared.panelState = .partiallyOpen
            print("Applying Partial")
            UIManager.shared.applyCompactWidgetLayout()
        }
    }

    // MARK: – Helpers
}
