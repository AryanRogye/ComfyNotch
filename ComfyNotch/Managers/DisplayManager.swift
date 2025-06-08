//
//  DisplayManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/8/25.
//

import Cocoa

/// The Display Manager will manage the displays that are connected to the
/// users laptop, it will collect and store information about the monitors

final class DisplayManager: NSObject, ObservableObject {
    static let shared = DisplayManager()
    
    @Published var screens : [NSScreen] = []
    
    private var timer: Timer?
    private var thread: Thread?

    public func start() {
        guard timer == nil else { return }
        
        /// Assign once at the start
        self.screens = NSScreen.screens
        
        self.thread = Thread {
            let runLoop = RunLoop.current
            
            let timer = Timer(timeInterval: 10.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.updateScreenInformation()
            }
            self.timer = timer
            
            runLoop.add(timer, forMode: .default)
            
            while !Thread.current.isCancelled {
                autoreleasepool {
                    runLoop.run(mode: .default, before: .distantFuture)
                }
            }
        }
        
        thread?.start()
    }
    
    public func stop() {
        thread?.cancel()
        timer?.invalidate()
        timer = nil
        thread = nil
    }
    
    private func updateScreenInformation() {
        self.screens = NSScreen.screens
        print("Screen Count: \(screens.count)")
    }
}
