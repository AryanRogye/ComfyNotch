//
//  Anim.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/21/25.
//

import SwiftUI

struct Anim {
    // macOS 14+ bouncy spring; fallback to a cubic curve
    static var spring: Animation {
        if #available(macOS 14, *) {
            .spring(.bouncy(duration: 0.40))
        } else {
            .timingCurve(0.16, 1, 0.3, 1, duration: 0.70)
        }
    }
    
    static let smooth = Animation.easeOut(duration: 0.15)
}
