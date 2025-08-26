import AppKit

class DisplayHandler {
    
    static let shared = DisplayHandler()
    
    private var lastRefreshTime: Date?

    func start() {
        let notificationCenter = NotificationCenter.default
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()
        
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        distributedCenter.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSNotification.Name("com.apple.spaces.didChange"),
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSWindow.didChangeScreenNotification,
            object: UIManager.shared.smallPanel
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSWindow.didChangeScreenNotification,
            object: UIManager.shared.smallPanel
        )
    }

    @objc private func handleScreenChange() {
        // Delay restart by 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            debugLog("Screen Changed, Re-Aligning Notch...", from: .display)
            UIManager.shared.re_align_notch()
        }
    }
}
