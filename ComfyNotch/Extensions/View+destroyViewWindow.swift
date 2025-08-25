//
//  View+destroyViewWindow.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/24/25.
//

import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        /// The NSView Destroys itself
        let v = WindowAccessorView()
        return v
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowAccessorView: NSView {
    private var didClose = false
    override func viewDidMoveToWindow() {
        guard !didClose else { return }
        didClose = true
        /// Close it
        window?.performClose(nil)
    }
}

extension View {
    public func destroyViewWindow() -> some View {
        self
            .background(WindowAccessor())
    }
}
