
import Foundation
import UserNotifications

/**
 * NotificationManager will be used in a way to pipe all notifications through
 * it. My main goal for this was to have notifications sent to this class
 * but apple has no public API for this. When I find the time to implement
 * something similar to this, I will add it here, But for now this will be used
 * to show some metal animations for the small panel, when a notification comes
 */
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    override init() {
        super.init()
        self.requestNotificationAuthorization()
        self.startListeningForNotifications()
    }
    
    /// Function that when a notification is about to show or 
    /// any notification event happens, it will call the functions on the 
    /// Self or (NotificationManager.shared)
    private func startListeningForNotifications() {
        /// is the system’s notification manager (macOS + iOS)
        UNUserNotificationCenter.current().delegate = self
    }
    /// This is the function that is automatically called when a notification happens
    /// Cuz of the "startListeningForNotifications" function
    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification received: \(notification.request.content.title) - \(notification.request.content.body)")
//        PanelAnimationState.shared.toggleBorderGlow()
    }
    
    /// Function to ask the user for permission to send notifications
    /// Shouldnt ask more than once
    private func requestNotificationAuthorization() {
            let center = UNUserNotificationCenter.current()
            /// Get the notification center
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus == .notDetermined else { return }
                /// If a request was able to be sent
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("🛑 Notification auth error: \(error)")
                    } else {
                        print("🔔 Notifications \(granted ? "granted" : "denied")")
                    }
                }
            }
    }
}

