//
//  ComfyNotchApp.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/17/25.
//

import SwiftUI

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

enum LogSource: String {
    case panels         = "|PanelStore|"
    case display        = "|DisplayManager|"
    case ui             = "|UIManager|"
    case mrmController  = "|MediaRemoteMusicController|"
    case aSController   = "|AppleScriptController|"
    case scroll         = "|ScrollManager|"
    case scrollMajor    = "|ScrollManager |MAJOR|"
    
    /// Most Likely These Will Be Always Active
    case settings       = "|Settings|"
    case fileTray       = "|FileTray|"
    case musicError     = "|MusicError|"
    /// All Widget Logic
    case widget         = "|Widget|"
}

func debugLog(_ message: @autoclosure () -> Any, from: LogSource? = nil) {
#if DEBUG
    let silencedSources: Set<LogSource> = [
        .panels,
        .display,
        .ui,
        .mrmController,
        .aSController,
        .scrollMajor
    ]
    
    if let from = from {
        if silencedSources.contains(from) {
            return
        }
        print("\(from): \(String(describing: message()))")
        return
    }
    print(message())
#endif
}
