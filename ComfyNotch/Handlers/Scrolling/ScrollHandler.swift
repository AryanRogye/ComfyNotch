import AppKit
import Combine

class ScrollHandler : ObservableObject {
    static let shared = ScrollHandler()
    
    internal let settings: SettingsModel = .shared
    
    // MARK: – Configuration
    var minPanelHeight: CGFloat = UIManager.shared.getNotchHeight()
    var maxPanelHeight: CGFloat = 110
    
    var minPanelWidth: CGFloat {
        settings.notchMinWidth
    }
    
    var maxPanelWidth: CGFloat {
        settings.notchMaxWidth
    }
    
    internal let maxPullDistance = 110
    
    // MARK: - Flags
    internal var isOpeningFull = false
    internal var isPeeking = false
    internal var isAnimatingPeek = false
    internal var isHovering = false
    
    private init() {}
    
    // MARK: - Open Full Panel
    /// This animation makes sure that it just "expands"
    
    func re_align_notch() {
        guard let panel = UIManager.shared.smallPanel else { return }
        guard UIManager.shared.panelState == .closed else { return }
        
        let screen = DisplayManager.shared.selectedScreen!
        let id = screen.displayID
        
        /// we want to look for the screen with the ID cuz the frame is not logging
        /// that its different, I had the resolution 1800x1169 and changed to 1512x982
        /// but the frame was still logging 1800x1169
        
        guard let screen = NSScreen.screens.first(where: {
            $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == id
        }) else {
            debugLog("❌ Could not find screen with displayID \(String(describing: id))")
            return
        }
        
        DispatchQueue.main.async {
            DisplayManager.shared.selectedScreen = screen
        }
        
        minPanelHeight = UIManager.shared.getNotchHeight()
        
        /// DEBUG LOG, this is DEBUG DEBUG working
//        debugLog("Screen Frame: \(screen.frame)")
//        debugLog("Screen Visible Frame: \(screen.visibleFrame)")
//        debugLog("Panel Screen Origin: \(panel.screen?.frame.origin ?? .zero)")
        
        let startYOffset = UIManager.shared.startPanelYOffset
        
        let finalWidth = minPanelWidth
        let centerX = (screen.frame.width - finalWidth) / 2
        let y = screen.frame.height - minPanelHeight - startYOffset
        let desiredFrame = NSRect(x: centerX, y: y, width: finalWidth, height: minPanelHeight)
        
        // Optional: Tolerance for micro pixel diff
        if !panel.frame.equalTo(desiredFrame) {
            panel.setFrame(desiredFrame, display: true)
        }
        
//        print("Set Values")
//        print("Min Height: \(minPanelHeight)")
//        print("Min Width: \(minPanelWidth)")
//        print("Panel Frame: \(panel.frame)")
//        print("Desired Frame: \(desiredFrame)")
    }
    
    // MARK: – Helpers
    func getNotchWidth() -> CGFloat {
        guard let screen = DisplayManager.shared.selectedScreen else { return 180 } // Default to 180 if it fails
        
        let screenWidth = screen.frame.width
        
        // Rough estimates based on Apple specs
        if screenWidth >= 3456 { // 16-inch MacBook Pro
            return 180
        } else if screenWidth >= 3024 { // 14-inch MacBook Pro
            return 160
        } else if screenWidth >= 2880 { // 15-inch MacBook Air
            return 170
        }
        
        // Default if we can't determine it
        return 230
    }
    
    // TODO: PLS PLS PLS LOOK AT THIS TO USE
    func animate(_ duration: TimeInterval,
                 timing: CAMediaTimingFunction,
                 animations: @escaping () -> Void,
                 completion: @escaping () -> Void = {}) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = timing
            ctx.allowsImplicitAnimation = true
            animations()
        }, completionHandler: completion)
    }
}
