//
//  NSPanel+animateFrame.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/18/25.
//

import AppKit

extension NSPanel {
    func animateFrame(
        to newFrame: NSRect,
        animateDuration duration: TimeInterval = 0.05,
        completion: (() -> Void)? = nil
    ) {
        // schedule the animated resize
        DispatchQueue.main.async {
            self.setFrame(newFrame, display: true, animate: true)
        }
        // fire your completion after the system animation finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }
}
