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
    
    
    
    // MARK: - Reduce Width
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
    
    // MARK: - Expand Width
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
    
    private var isAnimating = false
    
    // MARK: - Peeking Open for the PopInPresenter
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
        
        let normalHeight = minPanelHeight
        let normalY = currentTopY - normalHeight
        
        let startFrame = NSRect(
            x: panel.frame.origin.x,
            y: normalY,
            width: panel.frame.width,
            height: normalHeight
        )
        
        let targetFrame = NSRect(
            x: panel.frame.origin.x,
            y: peekY,
            width: panel.frame.width,
            height: peekHeight
        )
        
        // Set start position immediately before animation
        panel.setFrame(startFrame, display: false)
        DispatchQueue.main.async {
            panel.orderFront(nil)
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
                ctx.allowsImplicitAnimation = true
                
                panel.animator().setFrame(targetFrame, display: false)
            }, completionHandler: {
                self.isAnimating = false
            })
        }
    }
    
    // MARK: - Peeking Close For the PopInPresenter
    func peekClose() {
        guard let _ = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel,
              isPeeking,
              !isAnimating else { return }
        
        isAnimating = true
        isPeeking = false
        
        let currentTopY = panel.frame.maxY
        let normalHeight = minPanelHeight
        let normalY = currentTopY - normalHeight
        
        let startFrame = panel.frame
        let targetFrame = NSRect(
            x: startFrame.origin.x,
            y: normalY,
            width: startFrame.width,
            height: normalHeight
        )
        
        // Set start frame explicitly to current (just in case)
        panel.setFrame(startFrame, display: false)
        
        DispatchQueue.main.async {
            panel.orderFront(nil)
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.22
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
                ctx.allowsImplicitAnimation = true
                
                panel.animator().setFrame(targetFrame, display: false)
            }, completionHandler: {
                self.isAnimating = false
            })
        }
    }
    
    // MARK: - Peek Close Instantly
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
    
    // MARK: - Open Full Panel
    /// This animation makes sure that it just "expands"
    func openFull() {
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        
        isSnapping = true
        
        let current = panel.frame
        let trueH   = minPanelHeight + CGFloat(maxPullDistance)
        let finalW  = maxPanelWidth
        let dx      = finalW - current.width
        let x       = current.origin.x - dx / 2
        let trueY   = screen.frame.height - trueH
        let trueFrame = NSRect(x: x, y: trueY, width: finalW, height: trueH)
        
        let overshootAmount: CGFloat = -2
        let overH   = trueH + overshootAmount
        let overY   = screen.frame.height - overH
        let overFrame = NSRect(x: x, y: overY, width: finalW, height: overH)
        
        // Call correct animation style
        if settings.openingAnimation == "spring" {
            springAnimation(panel: panel, startFrame: current, overFrame: overFrame, trueFrame: trueFrame, trueH: trueH)
        } else if settings.openingAnimation == "iOS" {
            iOSAnimation(panel: panel, startFrame: current, overFrame: overFrame, trueFrame: trueFrame, trueH: trueH)
        }
    }
    
    private func springAnimation(
        panel: NSPanel,
        startFrame: NSRect,
        overFrame: NSRect,
        trueFrame: NSRect,
        trueH: CGFloat
    ) {
        let diveDur: TimeInterval = 0.25
        let recoDur: TimeInterval = 0.2
        let diveFn = CAMediaTimingFunction(controlPoints: 0.2, 1.2, 0.4, 1.0)
        let recoFn = CAMediaTimingFunction(controlPoints: 0.6, 1.8, 0.4, 1.0)
        
        panel.setFrame(startFrame, display: false)
        DispatchQueue.main.async {
            panel.orderFront(nil)
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = diveDur
                ctx.timingFunction = diveFn
                panel.animator().setFrame(overFrame, display: true)
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = recoDur
                    ctx.timingFunction = recoFn
                    panel.animator().setFrame(trueFrame, display: true)
                }, completionHandler: {
                    panel.setFrame(trueFrame, display: true)
                    self.isSnapping = false
                    self.updateState(for: trueH)
                    UIManager.shared.panelState = .open
                    self.verifyAndCorrectFrame(panel: panel, expectedFrame: trueFrame, expectedHeight: trueH)
                })
            })
        }
    }
    
    // MARK: - Animation Styles
    // NOTE: AnimationSettings will handle this
    private func iOSAnimation(
        panel: NSPanel,
        startFrame: NSRect,
        overFrame: NSRect,
        trueFrame: NSRect,
        trueH: CGFloat
    ) {
        let totalDuration: TimeInterval = 0.5
        let diveFn = CAMediaTimingFunction(controlPoints: 0.2, 0.0, 0.0, 1.0)
        let settleFn = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
        
        panel.setFrame(startFrame, display: false)
        DispatchQueue.main.async {
            panel.orderFront(nil)
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = totalDuration * 0.6
                ctx.timingFunction = diveFn
                panel.animator().setFrame(overFrame, display: true)
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = totalDuration * 0.4
                    ctx.timingFunction = settleFn
                    panel.animator().setFrame(trueFrame, display: true)
                }, completionHandler: {
                    panel.setFrame(trueFrame, display: true)
                    self.isSnapping = false
                    self.updateState(for: trueH)
                    UIManager.shared.panelState = .open
                    self.verifyAndCorrectFrame(panel: panel, expectedFrame: trueFrame, expectedHeight: trueH)
                })
            })
        }
    }
    
    private func verifyAndCorrectFrame(panel: NSPanel, expectedFrame: NSRect, expectedHeight: CGFloat) {
        let tolerance: CGFloat = 1.0 // Allow 1 pixel tolerance
        let actualFrame = panel.frame
        
        if abs(actualFrame.height - expectedHeight) > tolerance {
            print("Height mismatch! Expected: \(expectedHeight), Got: \(actualFrame.height)")
            // Force correct frame without animation
            panel.setFrame(expectedFrame, display: true)
        }
        
        self.isSnapping = false
        self.updateState(for: expectedHeight)
        UIManager.shared.panelState = .open
    }
    
    // MARK: - Close Full Panel
    func closeFull() {
        guard let panel = UIManager.shared.smallPanel, !isSnapping else { return }
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        
        PanelAnimationState.shared.currentPanelState = .home
        isSnapping = true
        PanelAnimationState.shared.isExpanded = false
        PanelAnimationState.shared.bottomSectionHeight = 0
        
        let startYOffset = UIManager.shared.startPanelYOffset
        let finalWidth = minPanelWidth
        let finalHeight = minPanelHeight
        
        let centerX = panel.frame.midX
        let centerY = screen.frame.height - finalHeight / 2 - startYOffset
        
        let finalFrame = NSRect(
            x: centerX - finalWidth / 2,
            y: centerY - finalHeight / 2,
            width: finalWidth,
            height: finalHeight
        )
        
        let undershoot: CGFloat = 0  // Adjust if you want extra bounce
        let underHeight = finalHeight - undershoot
        let underFrame = NSRect(
            x: centerX - finalWidth / 2,
            y: centerY - underHeight / 2,
            width: finalWidth,
            height: underHeight
        )
        
        let diveDuration: TimeInterval = 0.2
        let recoilDuration: TimeInterval = 0.15
        let diveCurve = CAMediaTimingFunction(controlPoints: 0.65, 1.0, 0.5, 1.0)
        let recoilCurve = CAMediaTimingFunction(controlPoints: 0.75, 1.0, 0.8, 1.0)
        
        // Explicit start position
        panel.setFrame(panel.frame, display: false)
        DispatchQueue.main.async {
            panel.orderFront(nil)
            
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
    
    // MARK: – Internals
    private func updateState(for height: CGFloat) {
        let open = (height >= maxPanelHeight)
        
        PanelAnimationState.shared.isExpanded = open
        PanelAnimationState.shared.bottomSectionHeight = open
        ? (height - minPanelHeight)
        : 0
        
        // MARK: - Open Logic
        if open {
            UIManager.shared.panelState = .open
            debugLog("Opening")
            UIManager.shared.applyExpandedWidgetLayout()
        }
        // MARK: - Close Logic
        else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
            debugLog("Closed")
            UIManager.shared.applyCompactWidgetLayout()
        }
        // MARK: - Partial Logic 
        else {
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
    
    // TODO: PLS PLS PLS LOOK AT THIS TO USE
    func animate(_ duration: TimeInterval,
                 timing: CAMediaTimingFunction,
                 animations: @escaping () -> Void,
                 completion: @escaping () -> Void = {}) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = timing
            ctx.allowsImplicitAnimation = true
            animations()
        }, completionHandler: completion)
    }
}
