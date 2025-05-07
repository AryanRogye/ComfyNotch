//
//  AppModeSwitcher.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/6/25.
//
import SwiftUI

enum AppModeSwitcher {
    static func temporarilyShowUI(for seconds: TimeInterval = 2.0) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    static func switchToUI() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func switchToAccessory() {
        NSApp.setActivationPolicy(.accessory)
    }
}
