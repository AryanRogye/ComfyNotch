
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App Did Finish Launching - Starting Setup") // <-- Add Debug Print

        UIManager.shared.setupFrame()         // Sets up the NSPanel and its content view
        ScrollManager.shared.start()          // Initializes scrolling (if needed)
        // Always Starts Closed

        print("Panel content view obtained successfully. Initializing widget.") // <-- Add Debug Print

        // Now you know panelContentView is not nil
        let musicPlayerWidget = MusicPlayerWidget()
        let timeWidget = TimeWidget()

        print("Widget initialized. Calling UIManager.addWidget...") // <-- Add Debug Print

        UIManager.shared.addWidget(timeWidget) // Add the TimeWidget to the panel
        UIManager.shared.addWidget(musicPlayerWidget)
        AudioManager.shared.startMediaTimer()
    }
}