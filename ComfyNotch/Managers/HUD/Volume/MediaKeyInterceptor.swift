//
//  MediaKeyInterceptor.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/4/25.
//

import AppKit

final class MediaKeyInterceptor {
    private var eventMonitor: Any?
    
    func start() {
        startMonitors()
    }
    
    // MARK: - Start Monitoring Sessions
    
    /// this really only triggeres for the volume, this is cuz the brightness does a check on itself not a key
    private func startMonitors() {
        debugLog("✅ Started Monitor", from: .volume)
        UIManager.shared.compactWidgetStore.setVolumeWidgets(icon: VolumeIcon(), number: VolumeNumber())
        VolumeManager.shared.hasStopped = false
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { event in
            guard event.subtype.rawValue == 8 else { return }
            
            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
            
            guard keyState else { return }
            
            print("sending")
            VolumeManager.shared.handleMediaKeyCode(keyCode)
        }
    }
    
    // MARK: - Stop Monitoring Sessions
    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        VolumeManager.shared.hasStopped = true
    }
}
