import AppKit

class DisplayHandler {
    static let shared = DisplayHandler()
    
    private var lastRefreshTime: Date?

    func start() {
//        let notificationCenter = NotificationCenter.default
//        let workspaceCenter = NSWorkspace.shared.notificationCenter
//        let distributedCenter = DistributedNotificationCenter.default()
//        
//        workspaceCenter.addObserver(
//            self,
//            selector: #selector(handleScreenWake),
//            name: NSWorkspace.didWakeNotification,
//            object: nil
//        )
//        notificationCenter.addObserver(
//            self,
//            selector: #selector(handleScreenChange),
//            name: NSApplication.didChangeScreenParametersNotification,
//            object: nil
//        )
//        distributedCenter.addObserver(
//            self,
//            selector: #selector(handleSpaceChanged),
//            name: NSNotification.Name("com.apple.spaces.didChange"),
//            object: nil
//        )
//        notificationCenter.addObserver(
//            self,
//            selector: #selector(handlePanelMoved),
//            name: NSWindow.didChangeScreenNotification,
//            object: UIManager.shared.userNotch
//        )
//        
//        notificationCenter.addObserver(
//            self,
//            selector: #selector(handlePanelMoved),
//            name: NSWindow.didChangeScreenNotification,
//            object: UIManager.shared.bigPanel
//        )
    }
    
    @objc private func handleWakeNotification() {
        logEvent("Screen Wake")
        refreshUI()
    }
    
    @objc private func handleScreenParametersChanged() {
        logEvent("Screen Parameters Changed")
        refreshUI()
    }
    
    @objc private func handleSpaceChanged() {
        logEvent("Space Changed")
        refreshUI()
    }
    
    @objc private func handlePanelMoved() {
        logEvent("Panel Moved Between Spaces/Screens")
        refreshUI()
    }
    
    private func refreshUI() {
        let now = Date()
        if let last = lastRefreshTime, now.timeIntervalSince(last) < 1.0 {
            print("Skipping refresh (too soon)")
            return
        }
        
        lastRefreshTime = now
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔄 Refreshing UI...")
            SettingsModel.shared.refreshUI()
        }
    }
    
    private func logEvent(_ event: String) {
        print("⚡️ Event detected: \(event)")
    }
    
    // Both Do the same thing but for knowing which is whcich i set into 2 different functions

    @objc func handleScreenWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("Restarting app due to screen change...")
            self.restartApp()
        }
    }

    @objc private func handleScreenChange() {
        // Delay restart by 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("Restarting app due to screen change...")
            self.restartApp()
        }
    }

    public func restartApp() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", Bundle.main.bundlePath]

        do {
            try task.run()  // Launch the new instance of the app
            task.waitUntilExit()  // Ensures the new instance starts before killing the old one
        } catch {
            print("Failed to launch a new instance: \(error)")
        }

        exit(0)  // Terminate the current instance
    }
}
