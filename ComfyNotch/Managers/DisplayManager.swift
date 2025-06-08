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
    
    @Published var screenSnapshots: [CGDirectDisplayID: NSImage?] = [:]
    @Published var selectedScreen: NSScreen!
    public var notchedScreen: NSScreen? {
        return NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 } )
    }
    
    private var timer: Timer?
    private var thread: Thread?
    
    override init() {
        super.init()
        
        /// TODO: Replace with loading in from the settings if nothing was found in the settings
        selectedScreen = notchedScreen ?? NSScreen.main
    }
    
    public func start() {
        guard timer == nil else { return }
        
        /// Assign once at the start
        updateScreenInformation()
        
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
    
    /// Function to get the image of the id super fast
    func snapshot(for id: CGDirectDisplayID) -> NSImage? {
        return screenSnapshots[id] ?? nil
    }
    
    /// Function to get the name of the screen
    func displayName(for displayID: CGDirectDisplayID) -> String {
        if let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) {
            return screen.localizedName
        }
        return "Unkown Name"
    }
    
    /// Function will generate a snapshot of the current screen
    /// used to show in the UI
    private func generateSnapShot(for screen: NSScreen) -> NSImage? {
        if let displayID = screen.displayID, let image = CGDisplayCreateImage(displayID) {
            return NSImage(cgImage: image, size: screen.frame.size)
        }
        
        return nil
    }
    
    private func updateScreenInformation() {
        for screen in NSScreen.screens {
            guard let id = screen.displayID else { continue }
            /// Dont generate a snapshot if it already exists
            if screenSnapshots[id] == nil {
                DispatchQueue.main.async {
                    self.screenSnapshots[id] = self.generateSnapShot(for: screen)
                }
            } else {
                /// If the snapshot already exists, we can update it if needed
                if let displayID = screen.displayID, let image = CGDisplayCreateImage(displayID) {
                    DispatchQueue.main.async {
                        self.screenSnapshots[id] = NSImage(cgImage: image, size: screen.frame.size)
                    }
                }
            }
        }
    }
}
