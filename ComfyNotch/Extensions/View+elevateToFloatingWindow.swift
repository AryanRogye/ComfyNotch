//
//  View+elevateToFloatingWindow.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI

extension View {
    func elevateToFloatingWindow() -> some View {
        self.background(WindowAccessor { window in
            guard let window else { return }

            // Prevent reapplying level multiple times
            if window.level != .floating {
                window.level = .floating
            }

            // Only bring to front if not already key
            if !window.isKeyWindow {
                window.makeKeyAndOrderFront(nil)
            }
        })
    }
}

// This helper grabs the NSWindow from the view hierarchy
private struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            onResolve(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
