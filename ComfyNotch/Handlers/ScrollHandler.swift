import AppKit
import Combine

class ScrollHandler {
    static let shared = ScrollHandler()
    
    private let settings: SettingsModel = .shared
    
    // MARK: – Configuration
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 150
    var minPanelWidth: CGFloat = 320
    
    var maxPanelWidth: CGFloat {
        settings.notchMaxWidth
    }
    
    private let maxPullDistance = 150
    /// Fine‑tune this multiplier to taste
    private let scrollSensitivity: CGFloat = 0.3
    private var panAccumulated: CGFloat = 0
    private var isSnapping = false
    private var isPeeking = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private var cachedPeekFrame: NSRect?
    private var cachedNormalFrame: NSRect?
    
    private init() {}
    // MARK: – Public API
    
    
    /// Handle Pan is what the view will call when a pan gesture is made
    // MARK: - Unused
    func handlePan(delta: CGFloat, phase: NSEvent.Phase) {
        /// Permananet Closing Logic, Works Perfectlly
        if UIManager.shared.panelState == .open,
           delta < 0, phase == .began {
            UIManager.shared.applyOpeningLayout()
            closeFull()
            return
        }
        /// - Mark: This is New For Scrolling Downwards For Opening
        if UIManager.shared.panelState == .closed,
           delta > 0, phase == .began {
            UIManager.shared.applyOpeningLayout()
            openFull()
            return
        }
    }
    
    func reduceWidth() {
        guard let panel = UIManager.shared.smallPanel else { return }
        
        if UIManager.shared.panelState == .closed {
            let newWidth: CGFloat = self.getNotchWidth()
            
            /// first hide the items inside it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIManager.shared.applyOpeningLayout()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PanelAnimationState.shared.currentPanelWidth = newWidth
            }
            /// then we wanna reduce the panel width
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                let screen = DisplayManager.shared.selectedScreen!
                
                let newX = (screen.frame.width - newWidth) / 2
                
                let reducedFrame = NSRect(
                    x: newX,
                    y: panel.frame.origin.y,
                    width: 0,
                    height: panel.frame.height
                )
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.25
                    ctx.timingFunction = CAMediaTimingFunction(name:.linear)
                    panel.animator().setFrame(reducedFrame, display: true)
                }
            }
        }
    }
    
    func expandWidth() {
        guard let panel = UIManager.shared.smallPanel,!isSnapping,!isPeeking else { return }
        
        if UIManager.shared.panelState == .closed {
            let newWidth: CGFloat = 320
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // we wanna expand the panel width
                let screen = DisplayManager.shared.selectedScreen!
                let newX = (screen.frame.width - newWidth) / 2
                let expandedFrame = NSRect(
                    x: newX,
                    y: panel.frame.origin.y,
                    width: newWidth,
                    height: panel.frame.height
                )
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.25
                    ctx.timingFunction = CAMediaTimingFunction(name:.linear)
                    panel.animator().setFrame(expandedFrame, display: true)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                PanelAnimationState.shared.currentPanelWidth = newWidth
                UIManager.shared.applyCompactWidgetLayout()
            }
        }
    }
    
    //    func peekOpen() {
    //        guard let panel = UIManager.shared.smallPanel,
    //            !isPeeking,
    //            !isSnapping else { return }
    //
    //        isPeeking = true
    //
    //        // Use cached frame or calculate once
    //        if cachedPeekFrame == nil {
    //            let peekHeight: CGFloat = minPanelHeight + 50
    //            let peekY = screen.frame.height - peekHeight - UIManager.shared.startPanelYOffset
    //
    //            cachedPeekFrame = NSRect(
    //                x: panel.frame.origin.x,
    //                y: peekY,
    //                width: panel.frame.width,
    //                height: peekHeight
    //            )
    //        }
    //
    //        // Method 1: Core Animation with explicit layer animation (FASTEST)
    //        CATransaction.begin()
    //        CATransaction.setDisableActions(false)
    //        CATransaction.setAnimationDuration(0.15) // Shorter duration
    //        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
    //
    //        panel.setFrame(cachedPeekFrame!, display: false) // KEY: display: false
    //
    //        CATransaction.commit()
    //    }
    //
    //    func peekClose() {
    //        guard let panel = UIManager.shared.smallPanel,
    //            isPeeking else { return }
    //
    //        isPeeking = false
    //
    //        // Use cached frame or calculate once
    //        if cachedNormalFrame == nil {
    //            let normalHeight = minPanelHeight
    //            let normalY = screen.frame.height - normalHeight - UIManager.shared.startPanelYOffset
    //
    //            cachedNormalFrame = NSRect(
    //                x: panel.frame.origin.x,
    //                y: normalY,
    //                width: panel.frame.width,
    //                height: normalHeight
    //            )
    //        }
    //
    //        CATransaction.begin()
    //        CATransaction.setDisableActions(false)
    //        CATransaction.setAnimationDuration(0.12) // Even shorter
    //        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
    //
    //        panel.setFrame(cachedNormalFrame!, display: false) // KEY: display: false
    //
    //        CATransaction.commit()
    //    }
    
    private var isAnimating = false

    func peekOpen() {
        guard let _ = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel,
              !isPeeking,
              !isSnapping,
              !isAnimating else { return }
        
        isPeeking = true
        isAnimating = true
        
        let currentTopY = panel.frame.maxY
        let peekHeight: CGFloat = minPanelHeight + 50
        let peekY = currentTopY - peekHeight
        
        let targetFrame = NSRect(
            x: panel.frame.origin.x,
            y: peekY,
            width: panel.frame.width,
            height: peekHeight
        )
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            ctx.allowsImplicitAnimation = true
            
            panel.animator().setFrame(targetFrame, display: false)
        }, completionHandler: {
            self.isAnimating = false
        })
    }
    
    func peekCloseInstantly() {
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel,
              isPeeking else { return }
        
        isPeeking = false
        
        let normalHeight = minPanelHeight
        let normalY = screen.frame.height - normalHeight - UIManager.shared.startPanelYOffset
        
        let targetFrame = NSRect(
            x: panel.frame.origin.x,
            y: normalY,
            width: panel.frame.width,
            height: normalHeight
        )
        
        panel.setFrame(targetFrame, display: true)
    }
    
    func peekClose() {
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel,
              isPeeking,
              !isAnimating else { return }
        
        isAnimating = true
        isPeeking = false
        
        let normalHeight = minPanelHeight
        let normalY = screen.frame.height - normalHeight - UIManager.shared.startPanelYOffset
        
        let targetFrame = NSRect(
            x: panel.frame.origin.x,
            y: normalY,
            width: panel.frame.width,
            height: normalHeight
        )
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            ctx.allowsImplicitAnimation = true
            
            panel.animator().setFrame(targetFrame, display: false)
        }, completionHandler: {
            self.isAnimating = false
        })
    }
    
    /// This animation makes sure that it just "expands"
    func openFull() {
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        /// Call A Peek Close First
        isSnapping = true
        
        let current = panel.frame
        
        // 1) true final
        let trueH     = minPanelHeight + CGFloat(maxPullDistance)
        let finalW    = maxPanelWidth
        let dx        = finalW - current.width
        let x         = current.origin.x - dx/2
        let trueY     = screen.frame.height - trueH
        let trueFrame = NSRect(x: x, y: trueY, width: finalW, height: trueH)
        
        // 2) bigger overshoot (flowier)
        let overshootAmount: CGFloat = -2   // ↑ more stretch
        let overH     = trueH + overshootAmount
        let overY     = screen.frame.height - overH
        let overFrame = NSRect(x: x, y: overY, width: finalW, height: overH)
        /// Super Clean Varient
        if settings.openingAnimation == "spring" {
            springAnimation(overFrame: overFrame, panel: panel, trueFrame: trueFrame, trueH: trueH)
        } else if settings.openingAnimation == "iOS" {
            iOSAnimation(overFrame: overFrame, panel: panel, trueFrame: trueFrame, trueH: trueH)
        }
        
    } /// Mark - End Of Open Full (Debugging Needed)
    
    private func springAnimation(
        overFrame: NSRect,
        panel: NSPanel,
        trueFrame: NSRect,
        trueH: CGFloat
    ) {
        //   3) super‑springy curves
        let diveDur: TimeInterval = 0.25
        let recoDur: TimeInterval = 0.2
        let diveFn   = CAMediaTimingFunction(controlPoints: 0.2, 1.2, 0.4, 1.0)
        let recoFn   = CAMediaTimingFunction(controlPoints: 0.6, 1.8, 0.4, 1.0)
        
        // Legacy Varient
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
    
    private func iOSAnimation(
        overFrame: NSRect,
        panel: NSPanel,
        trueFrame: NSRect,
        trueH: CGFloat
    ) {
        let totalDuration: TimeInterval = 0.5
        let diveFn = CAMediaTimingFunction(controlPoints: 0.2, 0.0, 0.0, 1.0)  // iOS ease-in-out
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = totalDuration * 0.6  // 60% for overshoot
            ctx.timingFunction = diveFn
            panel.animator().setFrame(overFrame, display: true)
        }) {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = totalDuration * 0.4  // 40% for settle
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
                panel.animator().setFrame(trueFrame, display: true)
            }) {
                panel.setFrame(trueFrame, display: true)
                self.isSnapping = false
                self.updateState(for: trueH)
                UIManager.shared.panelState = .open
            }
        }
    }
    
    func re_align_notch() {
        guard let panel = UIManager.shared.smallPanel else { return }
        guard UIManager.shared.panelState == .closed else { return }
        
        let screen = DisplayManager.shared.selectedScreen!
        let startYOffset = UIManager.shared.startPanelYOffset
        
        let finalWidth = minPanelWidth
        let finalHeight = minPanelHeight
        let centerX = (screen.frame.width - finalWidth) / 2
        let y = screen.frame.height - finalHeight - startYOffset
        let desiredFrame = NSRect(x: centerX, y: y, width: finalWidth, height: finalHeight)
        
        // Optional: Tolerance for micro pixel diff
        if !panel.frame.equalTo(desiredFrame) {
            panel.setFrame(desiredFrame, display: true)
        }
    }
    
    func closeFull() {
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        PanelAnimationState.shared.currentPanelState = .home
        isSnapping = true
        
        let screen       = DisplayManager.shared.selectedScreen!
        let startYOffset = UIManager.shared.startPanelYOffset
        
        let finalWidth   = minPanelWidth
        let finalHeight  = minPanelHeight
        let centerX      = panel.frame.midX  // ⬅️ preserve current center
        let centerY      = screen.frame.height - finalHeight / 2 - startYOffset
        
        let finalFrame = NSRect(
            x: centerX - finalWidth / 2,
            y: centerY - finalHeight / 2,
            width: finalWidth,
            height: finalHeight
        )
        
        // Optional: Undershoot logic
        let undershoot: CGFloat = 0
        let underHeight = finalHeight - undershoot
        let underFrame = NSRect(
            x: centerX - finalWidth / 2,
            y: centerY - underHeight / 2,
            width: finalWidth,
            height: underHeight
        )
        
        PanelAnimationState.shared.isExpanded = false
        PanelAnimationState.shared.bottomSectionHeight = 0
        
        let diveDuration: TimeInterval   = 0.2
        let recoilDuration: TimeInterval = 0.15
        let diveCurve = CAMediaTimingFunction(controlPoints: 0.65, 1.0, 0.5, 1.0)
        let recoilCurve = CAMediaTimingFunction(controlPoints: 0.75, 1.0, 0.8, 1.0)
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = diveDuration
            ctx.timingFunction = diveCurve
            panel.animator().setFrame(underFrame, display: true)
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = recoilDuration
                ctx.timingFunction = recoilCurve
                panel.animator().setFrame(finalFrame, display: true)
            }, completionHandler: {
                panel.setFrame(finalFrame, display: true)
                self.isSnapping = false
                self.updateState(for: finalHeight)
                UIManager.shared.panelState = .closed
            })
        })
    }
    
    // MARK: – Internals
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
            debugLog("Opening")
            UIManager.shared.applyExpandedWidgetLayout()
        } else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
            debugLog("Closed")
            UIManager.shared.applyCompactWidgetLayout()
        } else {
            UIManager.shared.panelState = .partiallyOpen
            debugLog("Applying Partial")
            UIManager.shared.applyOpeningLayout()
        }
    }
    
    // MARK: – Helpers
    func getNotchWidth() -> CGFloat {
        guard let screen = DisplayManager.shared.selectedScreen else { return 180 } // Default to 180 if it fails
        
        let screenWidth = screen.frame.width
        
        // Rough estimates based on Apple specs
        if screenWidth >= 3456 { // 16-inch MacBook Pro
            return 180
        } else if screenWidth >= 3024 { // 14-inch MacBook Pro
            return 160
        } else if screenWidth >= 2880 { // 15-inch MacBook Air
            return 170
        }
        
        // Default if we can't determine it
        return 180
    }
}
