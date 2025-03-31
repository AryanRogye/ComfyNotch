import AppKit

class ScrollManager {
    static let shared = ScrollManager()

    var scrollPadding: CGFloat = 15

    // Panel Values
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 100

    var minPanelWidth: CGFloat = 300
    var maxPanelWidth: CGFloat = 400

    private init() {

    }

    func start() {
        // Register for two-finger scroll events
        // Global monitor for events outside your app
        NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
            if self.isMouseInPanelRegion() {
                self.handleTwoFingerScroll(event)
            }
        }
    
        // Local monitor for events inside your app
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if self.isMouseInPanelRegion() {
                self.handleTwoFingerScroll(event)
            }
            return event
        }
    }

    private func isMouseInPanelRegion() -> Bool {
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        if let panel = UIManager.shared.panel {
            // Create a simple rectangular detection area exactly matching the panel
            // plus some padding around all sides
            let paddedFrame = NSRect(
                x: panel.frame.origin.x - scrollPadding,
                y: panel.frame.origin.y - scrollPadding,
                width: panel.frame.width + (scrollPadding * 2),
                height: panel.frame.height + (scrollPadding * 2)
            )
        
            return paddedFrame.contains(mouseLocation)
        }
        return false
    }

    private func handleTwoFingerScroll(_ event: NSEvent) {
        let scrollDeltaY = event.scrollingDeltaY

        if let panel = UIManager.shared.panel {
            // Calculate new height
            let newHeight = panel.frame.height + scrollDeltaY
            let clampedHeight = max(minPanelHeight, min(maxPanelHeight, newHeight))
    
            // Calculate new width proportionally to height change
            let heightPercentage = (clampedHeight - minPanelHeight) / (maxPanelHeight - minPanelHeight)
            let newWidth = minPanelWidth + (heightPercentage * (maxPanelWidth - minPanelWidth))
    
            // Apply clamping to width
            let clampedWidth = max(minPanelWidth, min(maxPanelWidth, newWidth))

            // Update the panel's size smoothly
            updatePanelSize(toHeight: clampedHeight, toWidth: clampedWidth)
            updatePanelState(for: clampedHeight)
        }
    }


    private func updatePanelSize(toHeight newHeight: CGFloat, toWidth newWidth: CGFloat) {
        guard let screen = NSScreen.main else { return }

        if let panel = UIManager.shared.panel {
            var panelFrame = panel.frame
            panelFrame.origin.y = screen.frame.height - newHeight - 2
            panelFrame.size.height = newHeight
            panelFrame.size.width = newWidth
            panelFrame.origin.x = (screen.frame.width - newWidth) / 2

            panel.setFrame(panelFrame, display: true, animate: true)
        }
    }

    public func updatePanelState(for height: CGFloat) {
        if height >= maxPanelHeight {
            UIManager.shared.panel_state = .OPEN
            UIManager.shared.showButtons()
            UIManager.shared.hideAlbumArtPanelView()
        } else if height <= minPanelHeight {
            UIManager.shared.panel_state = .CLOSED
            UIManager.shared.hideButtons()
            UIManager.shared.showAlbumArtPanelView()
        } else {
            UIManager.shared.panel_state = .PARTIALLY_OPEN
            UIManager.shared.hideButtons()
            UIManager.shared.hideAlbumArtPanelView()
        }
    }
}