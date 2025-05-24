//
//  VolumeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import AVFoundation
import SwiftUI
import Cocoa
import ApplicationServices

final class MediaKeyInterceptor {
    static let shared = MediaKeyInterceptor()
    
    private var eventMonitor: Any?
    private var fnKeyMonitor: Any?
    
    func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func requestAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }

    func start() {
        
        if !isAccessibilityEnabled() {
            requestAccessibility()
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { event in
            guard event.subtype.rawValue == 8 else { return }

            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA

            guard keyState else { return }

            VolumeManager.shared.handleMediaKeyCode(keyCode)
        }
        
        fnKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 122, event.modifierFlags.contains(.function) {
                // fn + F1
                print("✅ fn + F1 pressed")
//                BrightnessManager.shared.setBrightness(
//                    max(0, BrightnessManager.shared.getBrightness()! - 0.1)
//                )
//                PanelAnimationState.shared.currentPopInPresentationState = .brightness
            } else if event.keyCode == 120, event.modifierFlags.contains(.function) {
                // fn + F2
                print("✅ fn + F2 pressed")
//                BrightnessManager.shared.setBrightness(
//                    min(1, BrightnessManager.shared.getBrightness()! + 0.1)
//                )
//                PanelAnimationState.shared.currentPopInPresentationState = .brightness
            }
        }
    }

    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

final class VolumeManager: ObservableObject {
    static let shared = VolumeManager()
    
    private var osdSuppressionTimer: Timer?
    
    @Published var currentVolume: Float = 0
    
    init() {}
    
    public func start() {
        hideOSDUIHelper()
        
        // Optionally: keep suspending every few seconds in case macOS respawns it
        osdSuppressionTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            self.hideOSDUIHelper()
//            self.getCurrentSystemVolume()
        }
    }
    
    public func getCurrentSystemVolume() {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &defaultOutputDeviceID
        )
        if status != noErr {
            self.currentVolume = 0
            return
        }
        
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        var volume: Float32 = 0
        dataSize = UInt32(MemoryLayout<Float32>.size)
        let status2 = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &volume
        )
        if status2 != noErr {
            self.currentVolume = 0
            return
        }
        self.currentVolume = volume
        print("Current Volume: \(self.currentVolume)")
    }
    
    public func stop() {
        osdSuppressionTimer?.invalidate()
        osdSuppressionTimer = nil
        showOSDUIHelper()
        simulateVolumeKeyPress()
    }
    
    func simulateVolumeKeyPress() {
        let keyCode = NX_KEYTYPE_SOUND_UP
        let keyDownEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: (Int(keyCode) << 16) | (0xA << 8),
            data2: -1
        )
        
        keyDownEvent?.cgEvent?.post(tap: .cghidEventTap)
    }
    
    private func hideOSDUIHelper() {
        let kickstart = Process()
        kickstart.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        kickstart.arguments = ["kickstart", "gui/\(getuid())/com.apple.OSDUIHelper"]
        try? kickstart.run()
        kickstart.waitUntilExit()
        
        usleep(300000) // Give it time to respawn
        
        let suspend = Process()
        suspend.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        suspend.arguments = ["-STOP", "OSDUIHelper"]
        try? suspend.run()
    }
    
    private func showOSDUIHelper() {
        do {
            // Kill without sudo (may not always work)
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            kill.arguments = ["-9", "OSDUIHelper"]
            try kill.run()
            kill.waitUntilExit()

            // Wait longer
            usleep(2_000_000) // 2 seconds

            // Trigger through volume change (most reliable)
            let script = Process()
            script.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            script.arguments = ["-e", "set volume output volume (output volume of (get volume settings))"]
            try script.run()
            
            print("✅ OSDUIHelper restart triggered")
        } catch {
            print("❌ Failed to restart OSDUIHelper: \(error)")
        }
    }
    
    func handleMediaKeyCode(_ keyCode: Int) {
        switch Int32(keyCode) {
            
        case
        NX_KEYTYPE_SOUND_DOWN,              /// VOLUME DOWN
        NX_KEYTYPE_SOUND_UP,                /// VOLUME UP
        NX_KEYTYPE_MUTE,                    /// MUTE
        NX_KEYTYPE_BRIGHTNESS_DOWN,         /// BRIGHTNESS DOWN
        NX_KEYTYPE_BRIGHTNESS_UP,           /// BRIGHTNESS UP
        NX_KEYTYPE_ILLUMINATION_DOWN,       /// KEYBOARD_BRIGHTNESS_DOWN
        NX_KEYTYPE_ILLUMINATION_UP:         /// KEYBOARD BRIGHTNESS UP
            /// Trigger Notch Notch For Info
            triggerNotch()
        default:
            print("Unrecognized media key: \(keyCode)")
        }
    }
    
    private func triggerNotch() {
        getCurrentSystemVolume()
        if UIManager.shared.panelState != .open {
            /// Delay the animation by 0.25 seconds so it doesnt jitter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.2)) {
                    if UIManager.shared.panelState != .open {
                        PanelAnimationState.shared.currentPopInPresentationState = .volume
                        PanelAnimationState.shared.currentPanelState = .popInPresentation
                    }
                }
            }
            ScrollHandler.shared.peekOpen()
        }
    }
}
