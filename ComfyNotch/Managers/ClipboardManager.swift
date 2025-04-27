import Foundation
import SwiftUI

class ClipboardManager {
    static let shared = ClipboardManager()

    private var clipboardHistory: [String] = []
    private var timer: Timer?

    init() {}

    func getClipboardHistory() -> [String] {
        return clipboardHistory
    }

    /// Function to start monitoring clipboard changes.
    func start() {
        /// Poll Time:
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(SettingsModel.shared.clipboardManagerPollingIntervalMS), repeats: true) { [weak self] _ in
            self?.pollClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func pollClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            if clipboardString != clipboardHistory.last {
                clipboardHistory.append(clipboardString)
                if clipboardHistory.count > SettingsModel.shared.clipboardManagerMaxHistory {
                    clipboardHistory.removeFirst()
                }
            }
        }
    }
}