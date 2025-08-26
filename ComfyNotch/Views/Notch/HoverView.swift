//
//  HoverView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/23/25.
//

import SwiftUI
import AppKit
import Combine

struct HoverView: NSViewRepresentable {
    
    @Binding var isHovering: Bool
    
    init(isHovering: Binding<Bool>) {
        _isHovering = isHovering
    }
    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onHoverChange = { hovering in
            isHovering = hovering
        }
        return view
    }
    
    func updateNSView(_ nsView: TrackingView, context: Context) {}
}

class TrackingView: NSView {
    
    var onHoverChange: ((Bool) -> Void)?
    var globalTracker: GlobalTracker?
    
    private var cancellables: Set<AnyCancellable> = []
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        
        wantsLayer = true
        if layer == nil { layer = CALayer() } // ensure backing layer
        
        globalTracker = GlobalTracker(view: self)
        
        NotchStateManager.shared.$shouldVisualizeProximity
            .receive(on: RunLoop.main)
            .sink { [weak self] on in
                guard let self = self else { return }
                guard layer != nil else { return }
                
                self.animate("opacity",         to: on ? 1 : 0)
                self.animate("backgroundColor", to: (on ? NSColor.systemRed.withAlphaComponent(0.08) : .clear).cgColor)
                self.animate("borderColor",     to: (on ? NSColor.systemRed : .clear).cgColor)
                self.animate("borderWidth",     to: on ? 1 : 0)
                self.animate("shadowColor",     to: on ? NSColor.red.cgColor : .clear)
                self.animate("shadowOpacity",   to: on ? 0.4 : 0.0)
                self.animate("shadowOffset", to: on ? CGSize(width: 0, height: 3) : .zero)
                self.animate("shadowRadius",    to: on ? 6 : 0)
                self.animate("cornerRadius",    to: on ? 8 : 0)
                self.animate("transform.rotation", to: on ? 0.01 : 0)
                self.animate("lineDashPhase", to: on ? 10 : 0)
            }
            .store(in: &cancellables)
        
    }
    
    private func animate(_ key: String, to value: Any, duration: CFTimeInterval = 0.25) {
        guard let layer else { return }
        let from = layer.presentation()?.value(forKeyPath: key) ?? layer.value(forKeyPath: key)
        
        // Decide direction if numeric (for nicer curves)
        let isIncreasing: Bool = {
            switch (from, value) {
            case let (f as NSNumber, t as NSNumber): return t.doubleValue > f.doubleValue
            default: return true
            }
        }()
        
        let anim: CAPropertyAnimation
        
        if key == "opacity" {
            // Springy but tasteful for appear/disappear
            let spring = CASpringAnimation(keyPath: key)
            spring.fromValue = from
            spring.toValue   = value
            spring.damping = isIncreasing ? 16 : 18      // tiny bounce on appear, none on disappear
            spring.initialVelocity = isIncreasing ? 3 : 0
            spring.stiffness = 140
            spring.mass = 1
            spring.duration = spring.settlingDuration
            anim = spring
        } else {
            let basic = CABasicAnimation(keyPath: key)
            basic.fromValue = from
            basic.toValue   = value
            basic.duration  = duration
            
            // Overshoot on increase, clean ease on decrease
            if isIncreasing {
                // easeOutBack-ish
                basic.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
            } else {
                basic.timingFunction = CAMediaTimingFunction(name: .easeIn)
            }
            anim = basic
        }
        
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = true
        
        layer.add(anim, forKey: key)
        layer.setValue(value, forKeyPath: key) // commit final state
    }
    
    override func viewDidMoveToWindow() {
        if window == nil {
            globalTracker?.stop()
        } else {
            globalTracker?.startTracking() { [weak self] inside in
                guard let self = self else { return }
                self.onHoverChange?(inside)
            }
        }
        super.viewDidMoveToWindow()
    }
    
    deinit {
        globalTracker?.stop()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

class GlobalTracker {
    
    var isInside: Bool = false
    var localTracker: Any?
    var globalTracker: Any?
    weak var view: NSView?
    
    init(
        view: NSView? = nil,
    ) {
        self.view = view
    }
    
    func startTracking(completion: @escaping (Bool) -> Void) {
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            guard let view = self.view else { return }

            let screenLocation = NSEvent.mouseLocation /// Global Screen Coordinates
            /// This is where the view is
            let screenRect = view.window?.convertToScreen(view.convert(view.bounds, to: nil)) ?? .zero
            
            let inside = screenRect.contains(screenLocation)
            
            if inside != self.isInside {
                self.isInside = inside
                if Thread.isMainThread { completion(inside) }
                else { DispatchQueue.main.async { completion(inside) } }
                
                DispatchQueue.main.async {
                    if NotchStateManager.shared.shouldVisualizeProximity {
                        
                    }
                }
            }
        }
        
        globalTracker = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved], handler: handler)
        localTracker  = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { e in handler(e); return e }
    }
    
    func stop() {
        if let g = globalTracker { NSEvent.removeMonitor(g) }
        if let l = localTracker { NSEvent.removeMonitor(l) }
        globalTracker = nil; localTracker = nil
        isInside = false
    }
}
