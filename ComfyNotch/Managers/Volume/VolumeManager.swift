//
//  VolumeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import AVFoundation
import SwiftUI
import Cocoa
import AppKit
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
    
    func requestAccessibilityIfNeeded() {
        if !AXIsProcessTrusted() && !UserDefaults.standard.bool(forKey: "didRequestAccessibility") {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options)
            UserDefaults.standard.set(true, forKey: "didRequestAccessibility")
        }
    }
    
    func start() {
        
        requestAccessibilityIfNeeded()
        guard AXIsProcessTrusted() else { return }
        
        print("MediaKeyInterceptor started")

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
    
    let panelState = PanelAnimationState.shared
    let popInPresenterCoordinator = PopInPresenter_HUD_Coordinator.shared
    
    init() {}
    
    public func start() {
        DispatchQueue.global(qos: .utility).async {
            self.hideOSDUIHelper()

            DispatchQueue.main.async {
                self.osdSuppressionTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    DispatchQueue.global(qos: .utility).async {
                        self.hideOSDUIHelper()
                    }
                }
            }
        }
    }
    
    private func checkVolumeAppleScript() {
        let script = "output volume of (get volume settings)"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                if let vol = Float(output) {
                    self.currentVolume = vol / 100.0
                }
            }
        } else {
            self.currentVolume = 0
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
            checkVolumeAppleScript()
            return
        }
        
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
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
            checkVolumeAppleScript()
            return
        }
        self.currentVolume = volume
    }
    
    public func stop() {
        osdSuppressionTimer?.invalidate()
        osdSuppressionTimer = nil
        
        DispatchQueue.global(qos: .utility).async {
            self.showOSDUIHelper()
        }
        DispatchQueue.main.async {
            self.simulateVolumeKeyPress()
        }
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

            usleep(2_000_000) // 2 seconds

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
    
    private func refreshVolumeAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.getCurrentSystemVolume()
        }
    }
    
    private var debounceWorkItem: DispatchWorkItem?

    private func triggerNotch() {
        print("Notch Triggered")
        refreshVolumeAsync()

        debounceWorkItem?.cancel()

        // Show loading instantly
        panelState.isLoadingPopInPresenter = true

        // Open notch immediately
        openNotch()

        // Present the HUD slightly later
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }

            PopInPresenter_HUD_Coordinator.shared.presentIfAllowed(for: .volume) {
                withAnimation(.easeOut(duration: 0.2)) {
                    PanelAnimationState.shared.currentPopInPresentationState = .hud
                    PanelAnimationState.shared.currentPanelState = .popInPresentation
                }
                self.panelState.isLoadingPopInPresenter = false
            }
        }
    }
    
    private func openNotch() {
        ScrollHandler.shared.peekOpen()
    }
}
