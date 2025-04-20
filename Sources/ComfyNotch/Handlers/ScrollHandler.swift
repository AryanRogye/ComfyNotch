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
    private let scrollSensitivity: CGFloat = 0.5
    private var panAccumulated: CGFloat = 0

    /// How far off the small panel’s frame to snap back
    private var smallPanelRect: NSRect?
    private var isSnapping = false
    private let snapOpenThreshold: CGFloat   = 0.9
    private let snapClosedThreshold: CGFloat = 0.5

    private var offset: CGFloat
    private var accumulatedScrollDeltaY: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()
    private init() {
        // Grab initial Y‑offset from your settings
        offset = SettingsModel.shared.openStateYOffset

        // Save the tiny panel’s frame for snapping back
        if let panel = UIManager.shared.smallPanel {
            smallPanelRect = panel.frame
        }
    }

    // MARK: – Public API

    /// Handle Pan is what the view will call when a pan gesture is made
    func handlePan(delta: CGFloat, phase: NSEvent.Phase) {
        panAccumulated += delta

        switch phase {
        case .changed:
            process(delta: panAccumulated, phase: .changed)

        /// when closing the amount we "Panned" resets to 0
        case .ended, .cancelled:
            process(delta: panAccumulated, phase: phase)
            panAccumulated = 0        // reset for next gesture

        default:
            break
        }
    }

    /// This animation makes sure that it just "expands"
    func openFull() {
        guard let panel = UIManager.shared.smallPanel else { return }
        let screen = NSScreen.main!

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            var frame = panel.frame
            frame.size.height = minPanelHeight + CGFloat(maxPullDistance) // lock height
            frame.origin.y = screen.frame.height - frame.size.height - UIManager.shared.startPanelYOffset

            frame.size.width = maxPanelWidth
            frame.origin.x = (screen.frame.width - maxPanelWidth) / 2

            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            self.isSnapping = false
            self.updateState(for: self.maxPanelHeight)
        }
    }

    /// Same thing as openFull it just "closes"
    func closeFull() {
        guard let panel = UIManager.shared.smallPanel else { return }
        let screen = NSScreen.main!

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            var frame = panel.frame

            // 1. Shrink width first
            frame.size.width = minPanelWidth
            frame.origin.x = (screen.frame.width - minPanelWidth) / 2

            panel.animator().setFrame(frame, display: true)

        } completionHandler: { [weak self] in
            // 2. THEN shrink height
            self?.snapCloseHeight()
        }
    }

    // MARK: – Internals

    /// Function that does the animations
    private func process(delta: CGFloat, phase: NSEvent.Phase) {
        guard let panel = UIManager.shared.smallPanel else { return }
        /// This is that if the panel is currently getting adjusted "automatically" 
        /// any "pan" or "scroll" we do should cancel
        if isSnapping { return }

        // Ensure panel is visible
        if !panel.isVisible {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        }

        switch phase {
        case .changed:
            let screen = NSScreen.main!
            var frame = panel.frame

            let pullResistance: CGFloat = 0.5 // between 0.3 and 0.7 feels natural

            let rawPull = delta
            let adjustedPull = rawPull * pullResistance
            let clampedPull = max(-CGFloat(maxPullDistance), min(adjustedPull, CGFloat(maxPullDistance) + 100))

            /// 👇 PULLING DOWN LOGIC
            if clampedPull >= 0 {
                if clampedPull <= CGFloat(maxPullDistance) {
                    /// Grow height downwards first make sure that the width
                    /// Doesnt grow till after after it hits the maxPullDistance
                    let newHeight = minPanelHeight + clampedPull
                    frame.origin.y -= (newHeight - frame.size.height)
                    frame.size.height = newHeight
                    frame.size.width = minPanelWidth
                    frame.origin.x = (screen.frame.width - minPanelWidth) / 2
                } else {
                    /// After max pull distance, expand width
                    frame.size.height = minPanelHeight + CGFloat(maxPullDistance)

                    let extraPull = clampedPull - CGFloat(maxPullDistance)
                    let widthRatio = min(extraPull / 100, 1)

                    let newWidth = minPanelWidth + widthRatio * (maxPanelWidth - minPanelWidth)
                    frame.size.width = newWidth
                    frame.origin.x = (screen.frame.width - newWidth) / 2
                }

            }
            /// 👆 PULLING UP LOGIC
            else {
                let shrink = min(abs(clampedPull), panel.frame.height - minPanelHeight)
                let newHeight = panel.frame.height - shrink
                frame.size.height = newHeight
                frame.origin.y = screen.frame.height - newHeight - UIManager.shared.startPanelYOffset
                frame.size.width = minPanelWidth
                frame.origin.x = (screen.frame.width - minPanelWidth) / 2
            }
            /// Setting the Frame
            panel.setFrame(frame, display: true)

        case .ended, .cancelled:
//            openFull()
            isSnapping = true
            let totalPullDistance = delta
            let threshold: CGFloat = CGFloat(maxPullDistance) * 0.6 // Customize this (like 60% pull)

            if totalPullDistance >= threshold {
                openFull()
                UIManager.shared.panelState = .open
            } else {
                closeFull()
                UIManager.shared.panelState = .closed
            }
        default:
            break
        }
        updateState(for: panel.frame.height)
    }

    private func snapCloseHeight() {
        guard let panel = UIManager.shared.smallPanel else { return }
        let screen = NSScreen.main!
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            var frame = panel.frame
            frame.size.height = minPanelHeight
            frame.origin.y = screen.frame.height - minPanelHeight - UIManager.shared.startPanelYOffset

            panel.animator().setFrame(frame, display: true)

        } completionHandler: {
            self.isSnapping = false
        }
    }

    private func updateState(for height: CGFloat) {
        let open = (height >= maxPanelHeight)
        PanelAnimationState.shared.isExpanded = open
        PanelAnimationState.shared.bottomSectionHeight = open
          ? (height - minPanelHeight)
          : 0

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
