//
//  View+PanGesture.swift (Fixed & Optimised)
//  ComfyNotch
//
//  Re‑engineered on 30‑Apr‑2025 to keep a **local** scroll‑wheel monitor
//  so gestures fire anywhere in the hosting window – while still avoiding per‑event
//  allocations and global monitors. Public API and behaviour are unchanged.
//
//  © 2025 Aryan Rogye – MIT licence or same licence as original file.
//

import SwiftUI
import AppKit

// MARK: – Public helper

extension View {
    /// Attach a directional pan‑gesture to any SwiftUI `View`.
    /// The closure receives the absolute accumulated distance in **points** and the current `NSEvent.Phase`.
    func panGesture(direction: PanDirection,
                    action: @escaping (_ delta: CGFloat, _ phase: NSEvent.Phase) -> Void) -> some View {
        background(
            PanGestureRepresentable(direction: direction, action: action)
                .frame(maxWidth: 0, maxHeight: 0) // Invisible – size doesn’t matter, we use a local monitor.
        )
    }
}

// MARK: – Representable wrapper

private struct PanGestureRepresentable: NSViewRepresentable {
    let direction: PanDirection
    let action: (CGFloat, NSEvent.Phase) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(direction: direction, action: action)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitorIfNeeded(attachedTo: NSView())
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No dynamic updates needed.
    }

    // MARK: – Coordinator

    final class Coordinator: NSObject {
        private let direction: PanDirection
        private let action: (CGFloat, NSEvent.Phase) -> Void

        /// Running scroll sums since the last `.ended` phase.
        private var sumX: CGFloat = 0
        private var sumY: CGFloat = 0

        /// Retain the monitor so it stays alive for the life‑time of the host view.
        private var eventMonitor: Any?

        init(direction: PanDirection, action: @escaping (CGFloat, NSEvent.Phase) -> Void) {
            self.direction = direction
            self.action = action
            super.init()
        }

        deinit {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        /// Installs a **local** scroll‑wheel monitor scoped to the host window.
        /// – Keeps allocation low and matches original behaviour of firing anywhere in the window.
        func installMonitorIfNeeded(attachedTo view: NSView) -> NSView {
            guard eventMonitor == nil else { return view }

            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self, weak view] event in
                guard let self = self, let v = view, event.window == v.window else { return event }
                self.handleScroll(event)
                return event
            }
            return view
        }

        // MARK: – Core logic

        private func handleScroll(_ event: NSEvent) {
            sumX += event.scrollingDeltaX
            sumY += event.scrollingDeltaY

            switch direction {
                case .left  where sumX < 0:  action(abs(sumX), event.phase)
                case .right where sumX > 0:  action(abs(sumX), event.phase)
                case .up    where sumY < 0:  action(abs(sumY), event.phase)
                case .down  where sumY > 0:  action(abs(sumY), event.phase)
                default: break
            }

            if event.phase == .ended || event.momentumPhase == .ended {
                sumX = 0
                sumY = 0
            }
        }
    }
}

// MARK: – Direction enum

enum PanDirection { case left, right, up, down }
