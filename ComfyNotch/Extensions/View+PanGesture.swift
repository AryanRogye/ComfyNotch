//
//  View+PanGesture.swift (Optimized)
//  ComfyNotch
//
//  © 2025 Aryan Rogye – MIT licence
//

import SwiftUI
import AppKit

extension View {
    /// Attach a directional pan gesture to any SwiftUI view.
    /// The closure receives the absolute accumulated distance and current phase.
    func panGesture(direction: PanDirection,
                    action: @escaping (_ delta: CGFloat, _ phase: NSEvent.Phase) -> Void) -> some View {
        background(
            PanGestureRepresentable(direction: direction, action: action)
                .frame(maxWidth: 0, maxHeight: 0)
        )
    }
}

private struct PanGestureRepresentable: NSViewRepresentable {
    let direction: PanDirection
    let action: (CGFloat, NSEvent.Phase) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(direction: direction, action: action)
    }
    
    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitorIfNeeded(attachedTo: NSView())
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    final class Coordinator: NSObject {
        private let direction: PanDirection
        private let action: (CGFloat, NSEvent.Phase) -> Void
        
        private let isHorizontal: Bool
        private let isPositive: Bool
        private var sum: CGFloat = 0
        private var eventMonitor: Any?
        
        init(direction: PanDirection, action: @escaping (CGFloat, NSEvent.Phase) -> Void) {
            self.direction = direction
            self.action = action
            
            switch direction {
            case .left:
                (isHorizontal, isPositive) = (true, false)
            case .right:
                (isHorizontal, isPositive) = (true, true)
            case .up:
                (isHorizontal, isPositive) = (false, false)
            case .down:
                (isHorizontal, isPositive) = (false, true)
            }
            
            super.init()
        }
        
        deinit {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        
        func installMonitorIfNeeded(attachedTo view: NSView) -> NSView {
            guard eventMonitor == nil else { return view }
            
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self, weak view] event in
                guard let self = self,
                        let v = view,
                        event.window == v.window else { return event }
                self.handleScroll(event)
                return event
            }
            return view
        }
        
        @inline(__always)
        private func handleScroll(_ event: NSEvent) {
            let delta = isHorizontal ? event.scrollingDeltaX : event.scrollingDeltaY
            sum += delta
            
            let matchesDirection = isPositive ? sum > 0 : sum < 0
            
            if matchesDirection {
                action(abs(sum), event.phase)
            }
            
            if event.phase == .ended || event.momentumPhase == .ended {
                sum = 0
            }
        }
    }
}

enum PanDirection: CaseIterable {
    case left, right, up, down
}
