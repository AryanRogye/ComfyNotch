//
//  NotchSizeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/15/25.
//

import Foundation

/// Unused, but kept if I want to move Out the logic
final class NotchSizeManager: ObservableObject {
    static let shared = NotchSizeManager()
    
    private let settings: SettingsModel = .shared
    
    @Published var notchHeight: CGFloat = 0
    
    public let notchHeightMin : Int = 35
    public let notchHeightMax : Int = 50
    
    init() {
        let defaults = UserDefaults.standard
        let key = "notchHeightClosed"
        
        if let saved = defaults.object(forKey: key) as? CGFloat,
           saved >= CGFloat(notchHeightMin),
           saved <= CGFloat(notchHeightMax) {
            self.notchHeight = saved
        } else {
            getNotchHeight()
        }
    }
    
    public func reset() {
        getNotchHeightAsync()
    }
    
    public func getNotchHeightValues() -> CGFloat {
        if let screen = DisplayManager.shared.selectedScreen {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.top
        }
        return 0
    }
    
    public func setNewNotchHeight(with height: CGFloat) {
        guard height >= CGFloat(notchHeightMin) && height <= CGFloat(notchHeightMax) else {
            debugLog("Notch height must be between \(notchHeightMin) and \(notchHeightMax).")
            return
        }
        
        DispatchQueue.main.async {
            self.notchHeight = height
//            self.settings.saveNotchHeightClosed(for: height)
        }
    }
    
    private func getNotchHeightAsync() {
        if let screen = DisplayManager.shared.selectedScreen {
            let safeAreaInsets = screen.safeAreaInsets
            DispatchQueue.main.async {
                self.notchHeight = safeAreaInsets.top
//                self.settings.saveNotchHeightClosed(for: safeAreaInsets.top)
            }
        } else {
            DispatchQueue.main.async {
                self.notchHeight = 40
//                self.settings.saveNotchHeightClosed(for: 40)
            }
        }
    }

    private func getNotchHeight() {
        if let screen = DisplayManager.shared.selectedScreen {
            let safeAreaInsets = screen.safeAreaInsets
            self.notchHeight = safeAreaInsets.top
        } else {
            self.notchHeight = 40
        }
    }
}
