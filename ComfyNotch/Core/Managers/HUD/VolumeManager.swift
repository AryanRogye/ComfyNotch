//
//  VolumeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import AppKit
import AVFoundation

final class VolumeManager: ObservableObject {
    
    @Published var currentVolume: Float = 0
    
    private var osdSuppressionTimer: Timer?
    
    init() {}
    
    // MARK: - Key Code Handling
    func handleMediaKeyCode(_ keyCode: Int) {
        switch Int32(keyCode) {
            
        case
            NX_KEYTYPE_SOUND_DOWN,              /// VOLUME DOWN
            NX_KEYTYPE_SOUND_UP:                /// VOLUME UP
            refreshVolumeAsync()
            UIManager.shared.applyVolumeLayout()
        case
            NX_KEYTYPE_MUTE:                    /// MUTE
            self.currentVolume = 0
            UIManager.shared.applyVolumeLayout()
        default:
            break
        }
    }

    
    // MARK: - Start/Stop
    public func start() {
        debugLog("✅ Started", from: .volume)
        DispatchQueue.global(qos: .utility).async {
            /// On Start Hide OSDUIHelper
            self.hideOSDUIHelper()
            
            DispatchQueue.main.async {
                /// set a timer for every 3 seconds that kills it
                self.osdSuppressionTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    DispatchQueue.global(qos: .utility).async {
                        self.hideOSDUIHelper()
                    }
                }
            }
        }
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

    // MARK: - Getters For Volume
    private func refreshVolumeAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.getCurrentSystemVolume()
        }
    }

    // MARK: - Get System Volume (hard way)
    private func getCurrentSystemVolume() {
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
        
        guard status == noErr else {
            debugLog("Failed to get default output device: \(status)", from: .volume)
            checkVolumeAppleScript()
            return
        }
        
        // Check if the device supports volume control
        guard hasVolumeControl(deviceID: defaultOutputDeviceID) else {
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
        
        guard status2 == noErr else {
            debugLog("Failed to get volume: \(status2)", from: .volume)
            checkVolumeAppleScript()
            return
        }
        
        DispatchQueue.main.async {
            self.currentVolume = volume
        }
    }
    
    private func checkVolumeAppleScript() {
        let script = "output volume of (get volume settings)"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                if let vol = Float(output) {
                    DispatchQueue.main.async {
                        self.currentVolume = vol / 100.0
                    }
                }
            }
        } else {
            self.currentVolume = 0
        }
    }

    private func hasVolumeControl(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        return AudioObjectHasProperty(deviceID, &propertyAddress)
    }
    
    // MARK: - OSDUIHelper Functions
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
            
            debugLog("✅ OSDUIHelper restart triggered", from: .volume)
        } catch {
            debugLog("❌ Failed to restart OSDUIHelper: \(error)", from: .volume)
        }
    }
    
    private func simulateVolumeKeyPress() {
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
}
