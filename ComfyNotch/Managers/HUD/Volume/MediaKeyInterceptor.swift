//
//  MediaKeyInterceptor.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/4/25.
//

import AppKit
import Cocoa

final class MediaKeyInterceptor {
    private var eventTap: CFMachPort?
    
    func start() {
        startEventTap()
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }
    
    private func startEventTap() {
        UIManager.shared.compactWidgetStore.setVolumeWidgets(icon: VolumeIcon(), number: VolumeNumber())
        let mask = CGEventMask(1 << 14)
        
        
        let callback: CGEventTapCallBack = { _, _, event, _ in
            guard let nsEvent = NSEvent(cgEvent: event) else { return Unmanaged.passRetained(event) }
            
            guard nsEvent.subtype.rawValue == 8 else { return Unmanaged.passRetained(event) }
            
            let keyCode = ((nsEvent.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (nsEvent.data1 & 0x0000FFFF)
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
            
            guard keyState else { return Unmanaged.passRetained(event) }
            VolumeManager.shared.handleMediaKeyCode(keyCode)
            
            return Unmanaged.passRetained(event)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) else {
            print("❌ Failed to create CGEventTap.")
            return
        }
        
        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("✅ CGEventTap started")
    }
}
