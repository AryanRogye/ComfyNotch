import AppKit

// _ = SettingsModel.shared


/**
 * AppDelegate manages the application lifecycle and initialization of core components.
 * Responsible for setting up the UI, handlers, and loading widget configurations.
 *
 * Properties:
 * - hoverHandler: Manages hover interactions for the small panel
 */
public class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var appCoordinator : AppCoordinator?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        let _ = {
            NSKeyedUnarchiver.setClass(NSAttributedString.self, forClassName: "__NSCFAttributedString")
            NSKeyedUnarchiver.setClass(NSAttributedString.self, forClassName: "NSConcreteAttributedString")
            NSKeyedUnarchiver.setClass(NSAttributedString.self, forClassName: "NSFrozenAttributedString")
        }()
        
        Task { @MainActor in
            appCoordinator = AppCoordinator()
            appCoordinator?.start()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        appCoordinator?.end()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
