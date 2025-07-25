import AppKit
import SwiftUI

import AppKit
import SwiftUI

class PanelProximityHandler {
    private weak var panel: NSPanel?
    private var checkTimer: Timer?
    private var isHovering: Bool = false
    
    init() {
        self.panel = UIManager.shared.smallPanel
        startPolling()
    }
    
    deinit { checkTimer?.invalidate() }
    
    private func startPolling() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.evaluateProximity()
        }
    }
    
    private func evaluateProximity() {
        guard let panel = panel else { return }
        
        let mouse = NSEvent.mouseLocation
        let frame = panel.frame
        let dx = mouse.x - panel.frame.midX
        let dy = mouse.y - panel.frame.midY
        let dist = sqrt(dx * dx + dy * dy)
        
        // MARK: Hover logic (fires only on state change)
//        if frame.contains(mouse) {
//            if !isHovering {
//                isHovering = true
//                ScrollHandler.shared.hover(true)
//            }
//        } else {
//            if isHovering {
//                isHovering = false
//                ScrollHandler.shared.hover(false)
//            }
//        }
        
        // MARK: Auto-close if panel is open and cursor far away
        if UIManager.shared.panelState == .open, dist > 300, !SettingsModel.shared.isSettingsWindowOpen {
            
            /// Tasks to do if its open
            withAnimation(.easeInOut(duration: 0.1)) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIManager.shared.applyOpeningLayout()
                    ScrollHandler.shared.closeFull()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    /// IDK WHY THIS WILL MAKE TABS CHANGE
                    UIManager.shared.panelState = .closed
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotchStateManager.shared.isExpanded = false
                    NotchStateManager.shared.bottomSectionHeight = 0
                }
            }
            
        }
    }
}
