import AppKit
import Combine

class ScrollHandler {
    static let shared = ScrollHandler()
    
    // MARK: – Configuration
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 100
    var minPanelWidth:  CGFloat = 320
    var maxPanelWidth:  CGFloat = 700
    
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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: – PanGesture‑style state
    private var accumulatedScrollDeltaY: CGFloat = 0
    
    private init() {
        // Grab initial Y‑offset from your settings
        offset = SettingsModel.shared.openStateYOffset
        
        // Save the tiny panel’s frame for snapping back
        if let panel = UIManager.shared.userNotch {
            smallPanelRect = panel.frame
        }
    }
    
    // MARK: – Public API
    
    func handlePan(delta: CGFloat, phase: NSEvent.Phase) {
        // Combine successive scroll deltas exactly like PanGesture.Coordinator
        panAccumulated += delta
        
        // Treat "drag‑down increases height" and "drag‑up decreases height":
        //  ↓  = open  •  ↑  = close
        switch phase {
        case .changed:
            process(delta:  panAccumulated, phase: .changed)
            
        case .ended, .cancelled:
            process(delta:  panAccumulated, phase: phase)
            panAccumulated = 0        // reset for next gesture
            
        default:
            break
        }
    }
    
    
    // MARK: – Internals
    
    private func process(delta: CGFloat, phase: NSEvent.Phase) {
        guard let panel = UIManager.shared.userNotch else { return }
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
            
            
            if clampedPull >= 0 {
                // 👇 PULLING DOWN
                if clampedPull <= CGFloat(maxPullDistance) {
                    // 1️⃣ Grow height
                    let newHeight = minPanelHeight + clampedPull
                    frame.origin.y -= (newHeight - frame.size.height)
                    frame.size.height = newHeight
                    frame.size.width = minPanelWidth
                    frame.origin.x = (screen.frame.width - minPanelWidth) / 2
                } else {
                    // 2️⃣ After max pull distance, expand width
                    frame.size.height = minPanelHeight + CGFloat(maxPullDistance)
                    
                    let extraPull = clampedPull - CGFloat(maxPullDistance)
                    let widthRatio = min(extraPull / 100, 1)
                    
                    let newWidth = minPanelWidth + widthRatio * (maxPanelWidth - minPanelWidth)
                    frame.size.width = newWidth
                    frame.origin.x = (screen.frame.width - newWidth) / 2
                }
                
            } else {
                // 👆 PULLING UP
                let shrink = min(abs(clampedPull), panel.frame.height - minPanelHeight)
                let newHeight = panel.frame.height - shrink
                frame.size.height = newHeight
                frame.origin.y = screen.frame.height - newHeight - UIManager.shared.startPanelYOffset
                frame.size.width = minPanelWidth
                frame.origin.x = (screen.frame.width - minPanelWidth) / 2
            }
            
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
    }
    
    func openFull() {
        guard let panel = UIManager.shared.userNotch else { return }
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
    
    func closeFull() {
        guard let panel = UIManager.shared.userNotch else { return }
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
    
    private func snapCloseHeight() {
        guard let panel = UIManager.shared.userNotch else { return }
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
        if height >= maxPanelHeight {
            UIManager.shared.panelState = .open
        } else if height <= minPanelHeight {
            UIManager.shared.panelState = .closed
        } else {
            UIManager.shared.panelState = .partiallyOpen
        }
    }
    
    // MARK: – Helpers
}


///  From BoringNotch
///  I used this from Boring Notch for the panGesture
///
///  Example:
///     (some View())
///     .panGesture(direction: .down) { delta, phase in
///         ScrollHandler.shared.handlePan(delta: delta, phase: phase)
///     }
///  Created by Richard Kunkli on 21/08/2024.
///

import SwiftUI
import AppKit

extension View {
    func panGesture(direction: PanDirection, action: @escaping (CGFloat, NSEvent.Phase) -> Void) -> some View {
        background(
            PanGestureView(direction: direction, action: action)
                .frame(maxWidth: 0, maxHeight: 0)
        )
    }
}

struct PanGestureView: NSViewRepresentable {
    let direction: PanDirection
    let action: (CGFloat, NSEvent.Phase) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
            if event.window == view.window {
                context.coordinator.handleEvent(event)
            }
            return event
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(direction: direction, action: action)
    }
    
    class Coordinator: NSObject {
        let direction: PanDirection
        let action: (CGFloat, NSEvent.Phase) -> Void
        
        var accumulatedScrollDeltaX: CGFloat = 0
        var accumulatedScrollDeltaY: CGFloat = 0
        
        init(direction: PanDirection, action: @escaping (CGFloat, NSEvent.Phase) -> Void) {
            self.direction = direction
            self.action = action
        }
        
        @objc func handleEvent(_ event: NSEvent) {
            if event.type == .scrollWheel {
                accumulatedScrollDeltaX += event.scrollingDeltaX
                accumulatedScrollDeltaY += event.scrollingDeltaY
                
                switch direction {
                    case .down:
                        if accumulatedScrollDeltaY > 0 {
                            handle()
                        }
                    case .up:
                        if accumulatedScrollDeltaY < 0 {
                            handle()
                        }
                    case .left:
                        if accumulatedScrollDeltaX < 0 {
                            handle()
                        }
                    case .right:
                        if accumulatedScrollDeltaX > 0 {
                            handle()
                        }
                }
                
                func handle() {
                    if (direction == .left || direction == .right) {
                        action(abs(accumulatedScrollDeltaX), event.phase)
                    } else {
                        action(abs(accumulatedScrollDeltaY), event.phase)
                    }
                }
                
                if event.phase == .ended {
                    accumulatedScrollDeltaY = 0
                    accumulatedScrollDeltaX = 0
                }
            }
        }
    }
}

enum PanDirection {
    case left
    case right
    case up
    case down
}
