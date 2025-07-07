//
//  HUDManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/6/25.
//

import Foundation

final class HUDManager: ObservableObject {
    public func start() {
        if SettingsModel.shared.enableNotchHUD {
            /// Start The Media Key Interceptor
            MediaKeyInterceptor.shared.start()
            /// Start Volume Manager
            VolumeManager.shared.start()
            BrightnessWatcher.shared.start()
        }
    }
}
