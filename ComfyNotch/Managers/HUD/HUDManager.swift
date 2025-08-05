//
//  HUDManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/6/25.
//

import AppKit
import ApplicationServices

final class HUDManager {
    
    let mediaKeyInterceptor: MediaKeyInterceptor = MediaKeyInterceptor()
    
    var isAccessibilityEnabled: Bool = false
    
    public func start() {
        if SettingsModel.shared.enableNotchHUD {
            
            isAccessibilityEnabled = AXIsProcessTrusted()
            if isAccessibilityEnabled {
                realStart()
                return
            }
            
            self.requestAccessibility { granted in
                self.isAccessibilityEnabled = granted
                if granted {
                    self.realStart()
                } else {
                    debugLog("HUD Not Started Due To Accessibility Denial")
                    self.openAccessibilitySettings()
                }
            }
        }
    }
    
    private func realStart() {
        /// Start The Media Key Interceptor
        mediaKeyInterceptor.start()
        /// Start Volume Manager
        VolumeManager.shared.start()
        /// Start the Brightness Manager
        BrightnessWatcher.shared.start()
    }
    
    public func stop() {
        mediaKeyInterceptor.stop()
        VolumeManager.shared.stop()
        BrightnessWatcher.shared.stop()
    }
    
    func openAccessibilitySettings() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
        
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func requestAccessibility(completion: @escaping (Bool) -> Void) {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        
        // Trigger the prompt
        _ = AXIsProcessTrustedWithOptions(options)
        
        // Poll up to 10 seconds until access is granted
        var tries = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let granted = AXIsProcessTrusted()
            tries += 1
            
            if granted || tries > 10 {
                timer.invalidate()
                completion(granted)
            }
        }
    }
}
