//
//  ScrollHover.swift
//  ComfyNothcUIPrototype
//
//  Created by Aryan Rogye on 7/24/25.
//

import AppKit

extension ScrollHandler {
    
    private static let hoverScaleX: CGFloat = 1.05
    private static let hoverScaleY: CGFloat = 1.12
    private static let hoverInDuration: TimeInterval = 0.3
    private static let hoverOutDuration: TimeInterval = 0.2
    private static let shadowOpacity: Float = 0.15
    private static let shadowRadius: CGFloat = 8
    private static let hoverOutDelay: TimeInterval = 0.05
    
    func hover(_ hovering: Bool) {
        guard let panel = UIManager.shared.smallPanel,
              UIManager.shared.panelState == .closed,
              !isOpeningFull, !isPeeking, !isAnimatingPeek else { return }
        
        if hovering {
            guard !isHovering else { return }
            isHovering = true
            hoverIn(panel: panel)
        } else {
            guard isHovering else { return }
            
            // Use a shorter delay for more responsive feel
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.hoverOutDelay) {
                guard !self.isHovering else { return } // Double-check state
                self.hoverOut(panel: panel)
            }
            isHovering = false // Set immediately to prevent double-triggers
        }
    }
    
    private func hoverIn(panel: NSPanel) {
        guard let view = panel.contentView else { return }
        
        // Cancel any existing hover-out animations
        view.layer?.removeAnimation(forKey: "hoverOut")
        view.layer?.removeAnimation(forKey: "shadowOut")
        
        // Compute the enlarged "hover" frame
        let current = panel.frame
        let newW = current.width * Self.hoverScaleX
        let newH = current.height * Self.hoverScaleY
        let newX = current.minX - (newW - current.width) / 2
        let newY = current.minY - (newH - current.height) / 2
        let hoverFrame = NSRect(x: newX, y: newY, width: newW, height: newH)
        
        // Setup shadow layer
        setupShadowLayer(for: view)
        
        // Animate frame with spring-like easing
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = Self.hoverInDuration
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)  // Custom easing
            ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(hoverFrame, display: true)
        }, completionHandler: {
            self.finishedHoveringIn = true
        })
        
        // Animate shadow with separate timing for smoother effect
        animateShadow(for: view, to: Self.shadowOpacity, duration: Self.hoverInDuration, key: "shadowIn")
    }
    
    private func hoverOut(panel: NSPanel) {
        guard let screen = DisplayManager.shared.selectedScreen,
              let view = panel.contentView else { return }
        
        // Cancel any existing hover-in animations
        view.layer?.removeAnimation(forKey: "hoverIn")
        view.layer?.removeAnimation(forKey: "shadowIn")
        
        // Compute the original frame
        let originalFrame = computeOriginalFrame(screen: screen)
        
        // Animate frame back with faster, snappier timing
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = Self.hoverOutDuration
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0) // Snappy out
            ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(originalFrame, display: true)
        })
        
        // Fade out shadow faster
        animateShadow(for: view, to: 0, duration: Self.hoverOutDuration * 0.8, key: "shadowOut")
        self.finishedHoveringIn = false
    }
    
    private func setupShadowLayer(for view: NSView) {
        view.wantsLayer = true
        guard let layer = view.layer else { return }
        
        // Only setup shadow properties once
        if layer.shadowColor == nil {
            layer.shadowColor = NSColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: -2) // Slight downward shadow
            layer.shadowRadius = Self.shadowRadius
        }
    }
    
    private func animateShadow(for view: NSView, to opacity: Float, duration: TimeInterval, key: String) {
        guard let layer = view.layer else { return }
        
        let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnim.fromValue = layer.shadowOpacity
        shadowAnim.toValue = opacity
        shadowAnim.duration = duration
        shadowAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shadowAnim.fillMode = .forwards
        shadowAnim.isRemovedOnCompletion = false
        
        layer.add(shadowAnim, forKey: key)
        layer.shadowOpacity = opacity
    }
    
    private func computeOriginalFrame(screen: NSScreen) -> NSRect {
        let originalW = minPanelWidth
        let originalH = minPanelHeight
        let centerX = (screen.frame.width - originalW) / 2
        let originY = screen.frame.height - originalH - UIManager.shared.startPanelYOffset
        return NSRect(x: centerX, y: originY, width: originalW, height: originalH)
    }
}
