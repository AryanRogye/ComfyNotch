
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UIManager.shared.setupFrame()
        ScrollManager.shared.start()

        // FOR NOW WE ARE GOING TO ADD THE WIDGETS HERE
        // Later on i want to add a easier way to add widgets, maybe a settings in a toolbar,
        // obv will have to exit out of appkit and move to swiftui for that

        let musicPlayerWidget = MusicPlayerWidget()
        let timeWidget = TimeWidget()

        UIManager.shared.addWidget(musicPlayerWidget)
        UIManager.shared.addWidget(timeWidget) // Add the TimeWidget to the panel

        AudioManager.shared.startMediaTimer()
    }
}