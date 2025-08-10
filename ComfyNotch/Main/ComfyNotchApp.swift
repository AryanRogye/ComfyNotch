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

#if DEBUG
let VIEW_DEBUG_SPACING = false
let VIEW_MUSIC_SPACING = true
#endif


enum LogSource: String {
    case panels         = "|PanelStore|"
    case display        = "|DisplayManager|"
    case ui             = "|UIManager|"
    case mrmController  = "|MediaRemoteMusicController|"
    case aSController   = "|AppleScriptController|"
    case scroll         = "|ScrollManager|"
    case scrollMajor    = "|ScrollManager |MAJOR|"
    case hover          = "|HoverHandler|"
    
    case mKIntercept    = "|MediaKeyIntercept|"
    case brightness     = "|Brightness|"
    case volume         = "|Volume|"

    /// Most Likely These Will Be Always Active
    case settings       = "|Settings|"
    case fileTray       = "|FileTray|"
    case musicError     = "|MusicError|"
    /// All Widget Logic
    case widget         = "|Widget|"
}

@objc public class DebugLogger: NSObject {
    @objc public static func log(_ message: String, from source: String? = nil) {
#if DEBUG
        if let source = source {
            print("\(source): \(message)")
        } else {
            print(message)
        }
#endif
    }
}

func debugLog(_ message: @autoclosure () -> Any, from: LogSource? = nil) {
#if DEBUG
    let silencedSources: Set<LogSource> = [
        .display,
        .ui,
        .mrmController,
        .aSController,
        .scrollMajor,
        .hover
    ]
    
    if let from = from {
        if silencedSources.contains(from) {
            return
        }
        print("\(from.rawValue): \(String(describing: message()))")
        return
    }
    print(message())
#endif
}
