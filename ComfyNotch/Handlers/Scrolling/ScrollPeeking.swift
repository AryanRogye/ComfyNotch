//
//  ScrollPeeking.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/24/25.
//

import AppKit

extension ScrollHandler {
    // MARK: - Peeking Open for the PopInPresenter
    func peekOpen(withHeight: CGFloat? = nil) {
        guard let _ = DisplayManager.shared.selectedScreen else { return }
        guard let panel =
                UIManager.shared.smallPanel,
              !isPeeking,
              !isOpeningFull,
              !isAnimatingPeek else { return }
        
        isPeeking = true
        isAnimatingPeek = true
        
        let currentTopY = panel.frame.maxY
        let peekHeight: CGFloat = minPanelHeight + (withHeight ?? 50)
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
                self.isAnimatingPeek = false
            })
        }
    }
    
    // MARK: - Peeking Close For the PopInPresenter
    func peekClose() {
        guard let _ = DisplayManager.shared.selectedScreen else { return }
        guard let panel = UIManager.shared.smallPanel,
              isPeeking,
              !isAnimatingPeek else { return }
        
        isAnimatingPeek = true
        
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
                self.isAnimatingPeek = false
                self.isPeeking = false
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
}
