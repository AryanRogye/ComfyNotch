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

func killOtherComfyNotches() {
    let currentPID = ProcessInfo.processInfo.processIdentifier
    
    for app in NSWorkspace.shared.runningApplications {
        if let appName = app.localizedName, appName == "ComfyNotch" {
            if app.processIdentifier != currentPID {
                app.terminate()
            }
        }
    }
}

func debugLog(_ message: @autoclosure () -> Any) {
    #if DEBUG
    print(message())
    #endif
}

@main
struct ComfyNotchApp: App {
    init() {
    }
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Window("SettingsView", id: "SettingsView") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

#Preview {
    SettingsView()
}
