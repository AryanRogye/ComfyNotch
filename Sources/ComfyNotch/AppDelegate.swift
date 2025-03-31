
import AppKit
import MediaPlayer
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AudioManager.shared.startMediaTimer()
        UIManager.shared.setupFrame()
        ScrollManager.shared.start()
    }
}