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
            window?.level = .floating
            window?.makeKeyAndOrderFront(nil)
        })
    }
}

// This helper grabs the NSWindow from the view hierarchy
private struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.onResolve(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
