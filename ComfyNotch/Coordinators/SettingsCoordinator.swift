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
        
        if !SettingsModel.shared.isSettingsWindowOpen {
            windowCoordinator.showWindow(
                id: "settings",
                title: "Settings",
                content: view,
                size: NSSize(width: 800, height: 500),
                onOpen: {
                    NSApp.activate(ignoringOtherApps: true)
                    SettingsModel.shared.isSettingsWindowOpen = true
                    print("Settings Window Opened")
                },
                onClose: {
                    SettingsModel.shared.isSettingsWindowOpen = false
                    NSApp.activate(ignoringOtherApps: false)
                    print("Settings Window Closed")
                })
        }
    }
}
