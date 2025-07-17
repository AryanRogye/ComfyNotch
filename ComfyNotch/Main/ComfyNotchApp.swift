//
//  ComfyNotchApp.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/17/25.
//

import SwiftUI
import AppKit
import Sparkle
import Cocoa

func debugLog(_ message: @autoclosure () -> Any) {
    #if DEBUG
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
            .defaultLaunchBehavior(.suppressed)
        } else {
            return Window("SettingsView", id: "SettingsView") {
                SettingsView()
            }
            .windowResizability(.contentSize)
            .defaultPosition(.center)
        }
    }
}
