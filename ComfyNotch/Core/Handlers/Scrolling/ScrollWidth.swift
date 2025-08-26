//
//  ScrollWidth.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/24/25.
//

import AppKit

extension ScrollHandler {
    // MARK: - Reduce Width
    func reduceWidth() {
        guard let panel = UIManager.shared.smallPanel else { return }
        
        if UIManager.shared.panelState == .closed {
            let newWidth: CGFloat = self.getNotchWidth()
            debugLog("Using New Width: \(newWidth)", from: .scroll)
            
            /// first hide the items inside it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIManager.shared.applyOpeningLayout()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotchStateManager.shared.currentPanelWidth = newWidth
            }
            /// then we wanna reduce the panel width
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                let screen = DisplayManager.shared.selectedScreen!
                
                let newX = (screen.frame.width - newWidth) / 2
                
                let reducedFrame = NSRect(
                    x: newX,
                    y: panel.frame.origin.y,
                    width: newWidth,
                    height: panel.frame.height
                )
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.25
                    ctx.timingFunction = CAMediaTimingFunction(name:.linear)
                    panel.animator().setFrame(reducedFrame, display: true)
                } completionHandler: {
                    UIManager.shared.logPanelFrame(reason: "Reduced Width, New Frame")
                }
            }
        }
    }
    
    // MARK: - Expand Width
    func expandWidth() {
        guard let panel =
                UIManager.shared.smallPanel,
              !isOpeningFull,
              !isPeeking else { return }
        
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
                } completionHandler: {
                    UIManager.shared.logPanelFrame(reason: "Expanded Width, New Frame")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotchStateManager.shared.currentPanelWidth = newWidth
                UIManager.shared.applyCompactWidgetLayout()
            }
        }
    }
}
