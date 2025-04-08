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

    private func restartApp() {
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