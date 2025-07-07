//
//  DisplayManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/8/25.
//

import Cocoa
import ScreenCaptureKit

/// The Display Manager will manage the displays that are connected to the
/// users laptop, it will collect and store information about the monitors

/// TODO: Check in macOS 26 if the screen recording is good or UGH gotta figgure some shit out
final class DisplayManager: NSObject, ObservableObject {
    static let shared = DisplayManager()
    
    @Published var screenSnapshots: [CGDirectDisplayID: NSImage?] = [:]
    @Published var selectedScreen: NSScreen!
    public var notchedScreen: NSScreen? {
        return NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 } )
    }
    
    private var timer: Timer?
    private var thread: Thread?
    
    private var cachedPermission: Bool?
    
    override init() {
        super.init()
        
        selectedScreen = SettingsModel.shared.selectedScreen
    }
    
    public func start() {
        guard timer == nil else { return }
        
        //        if hasScreenRecordingPermission() {
        updateScreenInformation()
        //        } else {
        //            print("Screen recording permission missing. Skipping update.")
        //        }
        
        self.thread = Thread {
            let runLoop = RunLoop.current
            
            let timer = Timer(timeInterval: 10.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                //                if self.hasScreenRecordingPermission() {
                self.updateScreenInformation()
                //                }
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
    
    func saveSettings() {
        print("Saving Settings")
        SettingsModel.shared.saveSettingsForDisplay(for: selectedScreen)
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
        return "Unknown Name"
    }
    
    //    func hasScreenRecordingPermission() -> Bool {
    //        if let cached = cachedPermission {
    //            return cached
    //        }
    //
    //        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    //        let image = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution])
    //        let result = image != nil
    //        cachedPermission = result
    //        return result
    //    }
    
    //    func requestScreenRecordingPermission() {
    //        if #available(macOS 15, *) {
    //            // This will show the prompt if needed
    //            SCShareableContent.getWithCompletionHandler { _, _ in
    //                DispatchQueue.main.async {
    //                    self.cachedPermission = self.hasScreenRecordingPermission()
    //                }
    //            }
    //        } else {
    //            CGRequestScreenCaptureAccess()
    //            cachedPermission = hasScreenRecordingPermission()
    //        }
    //    }
    
    /// Function will generate a snapshot of the current screen
    /// used to show in the UI
    private func generateSnapShot(for screen: NSScreen) -> NSImage? {
        //        if let displayID = screen.displayID, let image = CGDisplayCreateImage(displayID) {
        //            return NSImage(cgImage: image, size: screen.frame.size)
        //        }
        
        return nil
    }
    
    private func updateScreenInformation() {
        for screen in NSScreen.screens {
            guard let id = screen.displayID else { continue }
            
            // get the size of the screen
            let size = screen.frame.size
            
            // create a blank NSImage of that size
            let image = NSImage(size: size)
            
            // optionally, fill it with a color (say light gray)
            image.lockFocus()
            NSColor.lightGray.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
            image.unlockFocus()
            
            // store it in your snapshot dictionary (if you want to keep it)
            DispatchQueue.main.async {
                self.screenSnapshots[id] = image
            }
            
            //            guard hasScreenRecordingPermission() else { continue }
            // Dont generate a snapshot if it already exists
            //            if screenSnapshots[id] == nil {
            //                DispatchQueue.global(qos: .userInitiated).async {
            //                    let snapshot = self.generateSnapShot(for: screen)
            //                    DispatchQueue.main.async {
            //                        self.screenSnapshots[id] = snapshot
            //                    }
            //                }
            //            } else {
            //                /// If the snapshot already exists, we can update it if needed
            //                if let image = CGDisplayCreateImage(id) {
            //                    DispatchQueue.global(qos: .userInitiated).async {
            //                        let image = NSImage(cgImage: image, size: screen.frame.size)
            //                        DispatchQueue.main.async {
            //                            self.screenSnapshots[id] = image
            //                        }
            //                    }
            //                }
            //            }
        }
    }
    
}
