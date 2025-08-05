//
//  NotchClickManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/6/25.
//

import AppKit
import SwiftUI

enum TouchAction: String, CaseIterable, Codable {
    case none
    case openFileTray
    case showUtils
    case openSettings
    
    var displayName: String {
        switch self {
        case .none:           "Do Nothing"
        case .openFileTray:   "Open File Tray"
        case .showUtils:      "Show Utilities"
        case .openSettings:   "Open Settings"
        }
    }
}


final class NotchClickManager: ObservableObject {
    
    private var eventMonitors: [Any] = []
    private let uiManager : UIManager = .shared
    private let settings: SettingsModel = .shared
    
    private var isMonitoring: Bool = false
    
    private var openWindow: OpenWindowAction?

    public func startMonitoring() {
        if isMonitoring { return }
        isMonitoring = true
        
        let leftClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            if self.uiManager.panelState == .closed {
                DispatchQueue.main.async {
                    if !NotchStateManager.shared.hoverHandler.isHoveringOverLeft &&
                        !NotchStateManager.shared.hoverHandler.isHoveringOverPlayPause &&
                        self.settings.isSettingsWindowOpen == false
                    {
                        self.handleFingerAction(for: self.settings.oneFingerAction)
                    }
                }
            }
            return event
        }
        let rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            if self.uiManager.panelState == .closed {
                if self.settings.isSettingsWindowOpen == false {
                    self.handleFingerAction(for: self.settings.twoFingerAction)
                }
            }
            return event
        }
        eventMonitors = [leftClickMonitor, rightClickMonitor].compactMap { $0 }
    }
    
    private func handleFingerAction(for finger: TouchAction) {
        switch finger {
        case .none:
            break
        case .openFileTray:
            openFileTray()
        case .showUtils:
            openUtils()
        case .openSettings:
            openSettings()
        }
    }
    
    public func stopMonitoring() {
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitors.removeAll()
        isMonitoring = false
    }
    
    // MARK: - Action Handlers
    
    private func openFileTray() {
        ScrollManager.shared.openFull()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NotchStateManager.shared.currentPanelState = .file_tray
        }
    }
    
    private func openUtils() {
        ScrollManager.shared.openFull()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NotchStateManager.shared.currentPanelState = .utils
        }
    }
    
    func setOpenWindow(_ action: OpenWindowAction?) {
        self.openWindow = action
    }
    
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow?(id: "SettingsView")
        settings.isSettingsWindowOpen = true
    }
}
