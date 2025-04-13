//
//  View+Window.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/13/25.
//

import SwiftUI

class FocusableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        makeFirstResponder(contentView)
    }
}

extension View {
    private func newWindowInternal(
        title: String,
        geometry: NSRect,
        style: NSWindow.StyleMask,
        delegate: NSWindowDelegate? = nil,
        level: NSWindow.Level = .normal
    ) -> NSWindow {
        let window = FocusableWindow(
            contentRect: geometry,
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.level = level
        if let delegate = delegate {
            window.delegate = delegate
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKey()
        window.makeFirstResponder(window.contentView)
        return window
    }
    
    func openNewWindow(title: String,
                       geometry: NSRect = NSRect(x: 20, y: 20, width: 640, height: 480),
                       style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable],
                       delegate: NSWindowDelegate? = nil) {
        self.newWindowInternal(title: title, geometry: geometry, style: style, delegate: delegate)
            .contentView = NSHostingView(rootView: self)
    }
}
