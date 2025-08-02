//
//  ComfyNotchApp.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/17/25.
//

import SwiftUI


func debugLog(_ message: @autoclosure () -> Any, from: String? = nil) {
#if DEBUG
    let silencedSources: Set<String> = [
        "PanelStore"
//        "DisplayManager"
//        "UIManager"
    ]
    
    if let from = from, silencedSources.contains(from) {
        return
    }
    
    print(message())
#endif
}

@main
struct ComfyNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        if #available(macOS 15.0, *) {
            return Window("SettingsView", id: "SettingsView") {
                SettingsView()
            }
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .windowStyle(.hiddenTitleBar)
            .defaultLaunchBehavior(.suppressed)
        } else {
            return Window("SettingsView", id: "SettingsView") {
                SettingsView()
            }
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .windowStyle(.hiddenTitleBar)
        }
    }
}
