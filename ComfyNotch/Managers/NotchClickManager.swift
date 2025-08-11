//
//  NotchClickManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/6/25.
//

import AppKit
import SwiftUI

enum TouchAction: String, CaseIterable, Codable {
    case openFileTray
    case openSettings
    case closeNotch
    
    var displayName: String {
        switch self {
        case .openFileTray:   "Open File Tray"
        case .openSettings:   "Open Settings"
        case .closeNotch  :   "Close Notch"
        }
    }
}

final class NotchClickManager {
    private let settings: SettingsModel = .shared
    private var openWindow: OpenWindowAction?
    
    public func handleFingerAction(for finger: TouchAction) {
        switch finger {
        case .openFileTray:
            openFileTray()
        case .openSettings:
            openSettings()
        case .closeNotch:
            closeNotch()
        }
    }
    
    // MARK: - Open FileTray
    private func openFileTray() {
        UIManager.shared.applyOpeningLayout()
        ScrollManager.shared.openFull()
        UIManager.shared.applyExpandedWidgetLayout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotchStateManager.shared.currentPanelState = .file_tray
        }
    }
    
    // MARK: - Open Utils
    private func openUtils() {
        ScrollManager.shared.openFull()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NotchStateManager.shared.currentPanelState = .utils
        }
    }
    
    // MARK: - Open Settings
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow?(id: "SettingsView")
        settings.isSettingsWindowOpen = true
    }
    
    // MARK: - Close Notch
    private func closeNotch() {
        // HAS TO BE OPEN or else we're just calling it for no reason
        guard UIManager.shared.panelState == .open else { return }
        UIManager.shared.applyOpeningLayout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ScrollManager.shared.closeFull()
        }
    }
    
    func setOpenWindow(_ action: OpenWindowAction?) {
        self.openWindow = action
    }
}
