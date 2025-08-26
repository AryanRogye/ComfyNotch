//
//  MediaKeyInterceptor.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/4/25.
//

import AppKit
import Cocoa
import SwiftUI

final class MediaKeyInterceptor {
    
    private var eventTap: CFMachPort?
    private let volumeManager = VolumeManager()
    
    // Static registry for the active interceptor
    private static weak var activeInterceptor: MediaKeyInterceptor?

    func start() {
        /// Make Sure no other instance is active but this one
        guard MediaKeyInterceptor.activeInterceptor == nil else {
            debugLog("⚠️ Another MediaKeyInterceptor is already running.", from: .mKIntercept)
            return
        }
        
        // Register this instance as the active one
        MediaKeyInterceptor.activeInterceptor = self
        
        startEventTap()
        
        /// Assign UI the Views
        let volumeNumber = VolumeNumber(volumeManager: volumeManager)
        
        UIManager.shared.compactWidgetStore.setVolumeWidgets(icon: VolumeIcon(), number: volumeNumber)
        UIManager.shared.compactWidgetStore.setBrightnessWidgets(icon: BrightnessIcon(), number: BrightnessNumber())
        
        /// Start Volume Manager
        volumeManager.start()
        /// Start the Brightness Manager
        BrightnessManager.sharedInstance().start()
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        
        // Unregister when stopping
        if MediaKeyInterceptor.activeInterceptor === self {
            MediaKeyInterceptor.activeInterceptor = nil
        }
        
        UIManager.shared.compactWidgetStore.removeVolumeWidgets()
        UIManager.shared.compactWidgetStore.removeBrightnessWidgets()

        volumeManager.stop()
        BrightnessManager.sharedInstance().stop()
    }
    
    private func startEventTap() {
        let mask = CGEventMask(1 << 14) // 14 = systemDefined

        // Static callback function - no captures
        let callback: CGEventTapCallBack = { _, type, event, _ in
            
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                return Unmanaged.passUnretained(event)
            }
            guard type.rawValue == 14 else { // only systemDefined events
                return Unmanaged.passUnretained(event)
            }
            
            guard let nsEvent = NSEvent(cgEvent: event) else {
                NSLog("⚠️ NSEvent creation failed — passing event through")
                return Unmanaged.passRetained(event)
            }
            guard nsEvent.subtype.rawValue == 8 else { return Unmanaged.passRetained(event) }
            
            let keyCode = ((nsEvent.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (nsEvent.data1 & 0x0000FFFF)
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
            
            guard keyState else { return Unmanaged.passRetained(event) }
            
            // Dispatch to the active interceptor
            MediaKeyInterceptor.activeInterceptor?.handleMediaKey(keyCode: keyCode)
            
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
            debugLog("❌ Failed to create CGEventTap.", from: .mKIntercept)
            return
        }
        
        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        debugLog("✅ CGEventTap started", from: .mKIntercept)
    }
    
    // Instance method to handle the media key
    private func handleMediaKey(keyCode: Int) {
        volumeManager.handleMediaKeyCode(keyCode)
        BrightnessManager.sharedInstance().handleMediaKeyCode(Int32(keyCode))
    }
}
