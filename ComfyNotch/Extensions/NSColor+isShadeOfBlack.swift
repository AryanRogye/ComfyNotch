//
//  NSColor+isShadeOfBlack.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/10/25.
//

import AppKit

extension NSColor {
    func isShadeOfBlack(threshold: CGFloat = 0.5) -> Bool {
        guard let rgbColor = self.usingColorSpace(.sRGB) else { return false }
        
        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        
        return red <= threshold && green <= threshold && blue <= threshold
    }
}
