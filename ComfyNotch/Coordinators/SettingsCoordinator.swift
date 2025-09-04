//
//  SettingsCoordinator.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/24/25.
//

import SwiftUI

@MainActor
class SettingsCoordinator: ObservableObject {
    
    let windowCoordinator: WindowCoordinator
    
    init(windows: WindowCoordinator) {
        self.windowCoordinator = windows
    }
    
    func showSettings() {
        
        let view = SettingsView()
        
        windowCoordinator.showWindow(
            id: "settings",
            title: "Settings",
            content: view,
            size: NSSize(width: 800, height: 500),
            onOpen: { [weak self] in
                SettingsModel.shared.isSettingsWindowOpen = true
                self?.activateWithRetry()
            },
            onClose: {
                SettingsModel.shared.isSettingsWindowOpen = false
                NSApp.activate(ignoringOtherApps: false)
            })
    }
    
    private func bringAppFront() {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true) // harmless double-tap; one of these usually “sticks”
    }
    
    private func activateWithRetry(_ tries: Int = 6) {
        guard tries > 0 else { return }
        
        // If we're already active *and* have a key window, stop retrying.
        if NSApp.isActive, NSApp.keyWindow != nil {
            return
        }
        
        bringAppFront()
        
        // Try again shortly — gives Spaces/full-screen a moment to switch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.activateWithRetry(tries - 1)
        }
    }
}
