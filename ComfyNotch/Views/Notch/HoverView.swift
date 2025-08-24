//
//  HoverView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/23/25.
//

import SwiftUI
import AppKit

struct HoverView: NSViewRepresentable {
    
    @Binding var isHovering: Bool
    
    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onHoverChange = { hovering in
            isHovering = hovering
        }
        return view
    }
    
    func updateNSView(_ nsView: TrackingView, context: Context) {
#if DEBUG
        if VIEW_DEBUG_SPACING {
            nsView.layer?.borderColor = NSColor.red.cgColor
            nsView.layer?.borderWidth = 1
        } else {
            nsView.layer?.borderColor = nil
        }
#endif
    }
}

class TrackingView: NSView {
    
    var onHoverChange: ((Bool) -> Void)?
    var globalTracker: GlobalTracker?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        globalTracker = GlobalTracker(view: self)
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
