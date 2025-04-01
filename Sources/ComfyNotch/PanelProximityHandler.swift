import AppKit

class PanelProximityHandler: NSObject {

    private weak var panel: NSPanel?


    private var localMonitor: Any?
    private var globalMonitor: Any?

    private var padding: CGFloat = 15
    private var distanceThreshold: CGFloat = 200

    init(panel: NSPanel) {
        self.panel = panel
        super.init()

        startListeningForPanelProximityWhenOpen()
    }

    deinit {
        stopMonitoring()
    }

    private func startListeningForPanelProximityWhenOpen() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
        
        // Global monitor for events outside our application
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
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

        // Don't open the panel with proximity, only allow closing
        if UIManager.shared.panel_state == .OPEN && !paddedFrame.contains(mouseLocation) {
            let distance = distanceFromPanel(to: mouseLocation, panelFrame: panelFrame)
            
            if distance > distanceThreshold && !SettingsModel.shared.isSettingsOpen {
                UIManager.shared.panel_state = .CLOSED
                ScrollManager.shared.close()
            }
        }
    }

    private func distanceFromPanel(to mouseLocation: NSPoint, panelFrame: NSRect) -> CGFloat {
        let panelCenter = NSPoint(x: panelFrame.midX, y: panelFrame.midY)
        let dx = mouseLocation.x - panelCenter.x
        let dy = mouseLocation.y - panelCenter.y
        return sqrt(dx * dx + dy * dy)
    }
}