import AppKit


class DisplayHandler {
    static let shared = DisplayHandler()

    func start() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self,
                                       selector: #selector(handleScreenWake),
                                       name: NSWorkspace.didWakeNotification,
                                       object: nil)

        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(handleScreenChange), 
                                               name: NSApplication.didChangeScreenParametersNotification, 
                                               object: nil)
    }
    
    @objc func handleScreenWake() {
        UIManager.shared.setupFrame()
    }

    @objc private func handleScreenChange() {
        // TODO: Handle display arrangement changes
    }
}