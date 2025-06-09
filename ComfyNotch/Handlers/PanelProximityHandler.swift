import AppKit
import SwiftUI

class PanelProximityHandler: NSObject {
    
    private weak var panel: NSPanel?
    
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    private var padding: CGFloat = 15
    private var distanceThreshold: CGFloat = 300
    
    init(panel: NSPanel) {
        self.panel = panel
        super.init()
        
        startListeningForPanelProximityWhenOpen()
    }
    
    deinit {
        stopMonitoring()
    }
    
    @objc func mouseEntered(_ event: NSEvent) {
        // you can leave this empty or toggle state
    }
    
    @objc func mouseExited(_ event: NSEvent) {
        // same deal
    }
    
    @objc func mouseMoved(_ event: NSEvent) {
        handleMouseMoved(event)
    }
    
    private func startListeningForPanelProximityWhenOpen() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, let _ = self.panel else { return event }
            self.handleMouseMoved(event)
            return event
        }
        
        // Global monitor for events outside our application
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, let _ = self.panel else { return }
            self.handleMouseMoved(event)
        }
        
        // Also add tracking area to the panel's content view
        if let contentView = panel?.contentView {
            let trackingArea = NSTrackingArea(
                rect: contentView.bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
                owner: self,
                userInfo: nil
            )
            contentView.addTrackingArea(trackingArea)
        }
    }
    
    private func stopMonitoring() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
    
    private func handleMouseMoved(_ event: NSEvent) {
        guard let panel = panel else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let panelFrame = panel.frame
        
        // Add padding to make it feel more natural
        let paddedFrame = NSRect(
            x: panelFrame.origin.x - padding,
            y: panelFrame.origin.y - padding,
            width: panelFrame.width + (padding * 2),
            height: panelFrame.height + (padding * 2)
        )
        
        /// Don't open the panel with proximity, only allow closing
        if (UIManager.shared.panelState == .open
            && !paddedFrame.contains(mouseLocation)) {
            let distance = distanceFromPanel(to: mouseLocation, panelFrame: panelFrame)
            
            if distance > distanceThreshold && !SettingsModel.shared.isSettingsWindowOpen {
                
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
                        PanelAnimationState.shared.isExpanded = false
                        PanelAnimationState.shared.bottomSectionHeight = 0
                    }
                }
            }
        }
    }
    
    private func distanceFromPanel(to mouseLocation: NSPoint, panelFrame: NSRect) -> CGFloat {
        let panelCenter = NSPoint(x: panelFrame.midX, y: panelFrame.midY)
        let deltaX = mouseLocation.x - panelCenter.x
        let deltaY = mouseLocation.y - panelCenter.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
}
