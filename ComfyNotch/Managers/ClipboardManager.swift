import Foundation
import SwiftUI

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var clipboardHistory: [String] = []
    private var lastClipboardContent: String?

    private var timer: Timer?

    init() {}


    /// Function to start monitoring clipboard changes.
    func start() {
        guard timer == nil else { return }
        /// Poll Time:
        timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(SettingsModel.shared.clipboardManagerPollingIntervalMS) / 1000.0,
            repeats: true
        ) { [weak self] _ in
            self?.pollClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func pollClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string),
           clipboardString != lastClipboardContent {
            lastClipboardContent = clipboardString
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.clipboardHistory.append(clipboardString)
                if self.clipboardHistory.count > SettingsModel.shared.clipboardManagerMaxHistory {
                    self.clipboardHistory.removeFirst()
                }
            }
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.clipboardHistory.removeAll()
        }
    }
}
