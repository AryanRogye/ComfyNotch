import Foundation
import SwiftUI

struct RingBuffer<Element> {
    private var storage: [Element?]
    private var head = 0      // index where the *next* write goes
    private(set) var count = 0
    
    init(capacity: Int) {
        storage = Array(repeating: nil, count: capacity)
    }
    
    mutating func push(_ value: Element) {
        storage[head] = value                 // overwrite oldest slot
        head = (head + 1) % storage.count     // wrap around
        if count < storage.count { count += 1 }
    }
    
    /// Latest → oldest
    var elements: [Element] {
        var result = [Element]()
        result.reserveCapacity(count)
        for i in 0..<count {
            let idx = (head - 1 - i + storage.count) % storage.count
            result.append(storage[idx]!)      // forced unwrap safe—slots filled
        }
        return result
    }
    
    mutating func clear() {
        storage.replaceSubrange(storage.indices, with: repeatElement(nil, count: storage.count))
        head = 0; count = 0
    }
}

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var clipboardHistory: [String] = []
    
    private var ring = RingBuffer<String>(capacity: SettingsModel.shared.clipboardManagerMaxHistory)

    private var lastChangeCount = NSPasteboard.general.changeCount
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
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        
        guard let str = pb.string(forType: .string),
              ring.elements.first != str else { return }
        
        ring.push(str)
        DispatchQueue.main.async { self.clipboardHistory = self.ring.elements }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.clipboardHistory.removeAll()
        }
    }
}
