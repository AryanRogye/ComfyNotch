//
//  WindowCoordinator.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/21/25.
//

import Foundation
import AppKit
import SwiftUI

private class WindowDelegate: NSObject, NSWindowDelegate {
    let id: String
    weak var coordinator: WindowCoordinator?
    
    init(id: String, coordinator: WindowCoordinator) {
        self.id = id
        self.coordinator = coordinator
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        coordinator?.handleWindowOpen(id: id)
    }
    
    func windowWillClose(_ notification: Notification) {
        coordinator?.handleWindowClose(id: id)
    }
}

/// Window Coordinator manages the lifecycle of multiple windows in the application.
class WindowCoordinator {
    
    private var windows : [String: NSWindow] = [:]
    
    private var onOpenAction : [String: (() -> Void)] = [:]
    private var onCloseAction : [String: (() -> Void)] = [:]
    
    private var delegates: [String: WindowDelegate] = [:]
    
    deinit {
        // Clean up all windows when the coordinator is deinitialized
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
    }
    
    func showWindow(
        id: String,
        title: String,
        content: some View,
        size: NSSize = .init(width: 600, height: 400),
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        if let window = windows[id] {
            // Re-activate app and bring the existing window up
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Match SwiftUI window modifiers
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        
        let hostingView = NSHostingView(rootView: content)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = hostingView
        
        /// Assign A Window Delegate
        let delegate = WindowDelegate(id: id, coordinator: self)
        window.delegate = delegate
        delegates[id] = delegate
        
        if let action = onClose {
            onCloseAction[id] = action
        }
        if let action = onOpen {
            onOpenAction[id] = action
        }
        
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        windows[id] = window
    }
    
    func closeWindow(id: String) {
        windows[id]?.close()
        /// windowWillClose will be called automatically
    }
    
    fileprivate func handleWindowOpen(id: String) {
        if let action = onOpenAction[id] {
            action()
            onOpenAction[id] = nil
        }
    }
    
    fileprivate func handleWindowClose(id: String) {
        windows[id] = nil
        delegates[id] = nil
        if let action = onCloseAction[id] {
            action()
            onCloseAction[id] = nil
        }
    }
}
