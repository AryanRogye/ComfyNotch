//
//  VolumeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import MediaKeyTap
import AVFoundation
import Cocoa

final class MediaKeyInterceptor {
    static let shared = MediaKeyInterceptor()
    
    private var eventMonitor: Any?

    func start() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { event in
            guard event.subtype.rawValue == 8 else { return }

            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA

            guard keyState else { return }

            VolumeManager.shared.handleMediaKeyCode(keyCode)
        }
    }

    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

final class VolumeManager {
    static let shared = VolumeManager()
    
    private var osdSuppressionTimer: Timer?
    
    init() {}
    
    public func start() {
        hideOSDUIHelper()
        
        // Optionally: keep suspending every few seconds in case macOS respawns it
        osdSuppressionTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            self.hideOSDUIHelper()
        }
    }
    
    public func stop() {
        osdSuppressionTimer?.invalidate()
        osdSuppressionTimer = nil
        showOSDUIHelper()
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
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            kill.arguments = ["-9", "OSDUIHelper"]
            try kill.run()
            kill.waitUntilExit()

            // short delay
            usleep(500_000)

            // kickstart it
            let kickstart = Process()
            kickstart.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            kickstart.arguments = ["kickstart", "-k", "gui/\(getuid())/com.apple.OSDUIHelper"]
            try kickstart.run()

            print("✅ OSDUIHelper successfully restarted")
        } catch {
            print("❌ Failed to restart OSDUIHelper: \(error)")
        }
    }
    
    func handleMediaKeyCode(_ keyCode: Int) {
        switch Int32(keyCode) {
        case NX_KEYTYPE_SOUND_DOWN:
            print("🔉 Volume Down")
        case NX_KEYTYPE_SOUND_UP:
            print("🔊 Volume Up")
        case NX_KEYTYPE_MUTE:
            print("🔇 Mute")
            
        case NX_KEYTYPE_BRIGHTNESS_DOWN:
            print("🔅 Brightness Down")
        case NX_KEYTYPE_BRIGHTNESS_UP:
            print("🔆 Brightness Up")
            
        case NX_KEYTYPE_ILLUMINATION_DOWN:
            print("💡 Keyboard Brightness Down")
        case NX_KEYTYPE_ILLUMINATION_UP:
            print("💡 Keyboard Brightness Up")
            
        default:
            print("Unrecognized media key: \(keyCode)")
        }
    }
}
