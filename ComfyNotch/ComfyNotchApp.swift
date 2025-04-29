//
//  ComfyNotchApp.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/17/25.
//

import SwiftUI
import AppKit
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

@main
struct ComfyNotchApp: App {
    
    init() {
        killOtherComfyNotches()
    }
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
