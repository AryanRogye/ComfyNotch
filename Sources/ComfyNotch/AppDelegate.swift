
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hoverHandler: HoverHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UIManager.shared.setupFrame()
        ScrollManager.shared.start()
        if let smallPanel = UIManager.shared.small_panel {
            self.hoverHandler = HoverHandler(panel: smallPanel)
        }

        // FOR NOW WE ARE GOING TO ADD THE WIDGETS HERE
        // Later on i want to add a easier way to add widgets, maybe a settings in a toolbar,
        // obv will have to exit out of appkit and move to swiftui for that

        let musicPlayerWidget = MusicPlayerWidget()
        let timeWidget = TimeWidget()

        UIManager.shared.addWidgetToBigPanel(musicPlayerWidget)
        UIManager.shared.addWidgetToBigPanel(timeWidget) // Add the TimeWidget to the panel

        AudioManager.shared.startMediaTimer()
    }
}