//
//  NotchClickManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/6/25.
//

import AppKit

final class NotchClickManager: ObservableObject {
    
    private var eventMonitors: [Any] = []
    private let animationState : PanelAnimationState = .shared
    private let uiManager : UIManager = .shared
    
    private var isMonitoring: Bool = false
    
    public func startMonitoring() {
        if isMonitoring { return }
        isMonitoring = true
        
        let leftClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            if self.uiManager.panelState == .closed {
                if !self.animationState.hoverHandler.isHoveringOverLeft && !self.animationState.hoverHandler.isHoveringOverPlayPause {
                    print("one-finger / left click detected")
                }
            }
            return event
        }
        let rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            if self.uiManager.panelState == .closed {
                print("two-finger / right click detected")
            }
            return event
        }
        eventMonitors = [leftClickMonitor, rightClickMonitor].compactMap { $0 }
    }
    
    public func stopMonitoring() {
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitors.removeAll()
        isMonitoring = false
    }
}
