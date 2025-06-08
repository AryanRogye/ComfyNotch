//
//  NSScreen+CGDirectDisplayID.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/8/25.
//

import Cocoa

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
