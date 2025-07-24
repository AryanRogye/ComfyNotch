//
//  ScrollOpening.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/24/25.
//

import AppKit

extension ScrollHandler {
    
    // MARK: – Updating State
    private func updateState(for height: CGFloat) {
        let open = (height >= maxPanelHeight)
        
        DispatchQueue.main.async {
            
            NotchStateManager.shared.isExpanded = open
            NotchStateManager.shared.bottomSectionHeight = open
            ? (height - self.minPanelHeight)
            : 0
        }
        
        // MARK: - Open Logic
        if open {
            UIManager.shared.panelState = .open
            /// DEBUG DEBUG LOGS
            //            debugLog("Opening")
            UIManager.shared.applyExpandedWidgetLayout()
        }
        // MARK: - Close Logic
        else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
            /// DEBUG DEBUG LOGS
            //            debugLog("Closed")
            UIManager.shared.applyCompactWidgetLayout()
        }
        // MARK: - Partial Logic
        else {
            UIManager.shared.panelState = .partiallyOpen
            /// DEBUG DEBUG LOGS
            //            debugLog("Applying Partial")
            UIManager.shared.applyOpeningLayout()
        }
    }

    // MARK: - Open Full
    func openFull() {
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        guard let panel =
                UIManager.shared.smallPanel,
              !isOpeningFull else { return }
        
        isOpeningFull = true
        
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
    
    // MARK: - Close Full Panel
    func closeFull() {
        guard let panel = UIManager.shared.smallPanel, !isOpeningFull else { return }
        guard let screen = DisplayManager.shared.selectedScreen else { return }
        
        DispatchQueue.main.async {
            NotchStateManager.shared.currentPanelState = .home
            self.isOpeningFull = true
            NotchStateManager.shared.isExpanded = false
            NotchStateManager.shared.bottomSectionHeight = 0
        }
        
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
                    self.isOpeningFull = false
                    self.updateState(for: finalHeight)
                    UIManager.shared.panelState = .closed
                })
            })
        }
    }

    // MARK: - Animations
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
                    self.isOpeningFull = false
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
                    self.isOpeningFull = false
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
        
        self.isOpeningFull = false
        self.updateState(for: expectedHeight)
        UIManager.shared.panelState = .open
    }
}
