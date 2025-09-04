//
//  ScrollManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/5/25.
//

import SwiftUI
import Combine

enum ScrollController {
    case old
    case new
}

class ScrollManager: ObservableObject {
    
    static let shared = ScrollManager()
    
    let scrollHandler = ScrollHandler()
    
    @Published var notchSize: (width: CGFloat, height: CGFloat) = (.zero, .zero)
    
    let DEFAULT_TOP_RADIUS : CGFloat = 8
    let DEFAULT_BOTTOM_RADIUS : CGFloat = 8
    @Published var notchRadius: (topRadius: CGFloat, bottomRadius: CGFloat) = (8, 8)
    
    let uiManager = UIManager.shared
    var scrollController = ScrollController.new
    
    let settings = SettingsModel.shared
    
    private var isOpeningFull = false
    private var isClosingFull = false
    private var isExpandingWidth = false
    
    private var isPeekingOpen = false
    private var isPeekingClose = false
    
    init() {
        notchSize = (width: getNotchWidth(), height: getNotchHeight())
    }
    
    public func getMaxPanelHeight() -> CGFloat {
        self.getNotchHeight() + 110
    }
    
    public func openFull() {
        switch scrollController {
        case .new: openFullNew()
        case .old: break
        }
    }
}

extension ScrollManager {
    // MARK: – Helpers
    func getNotchWidth() -> CGFloat {
        guard let screen = DisplayManager.shared.selectedScreen else { return 180 }
        
        if let topLeftSpace: CGFloat = screen.auxiliaryTopLeftArea?.width,
           let topRightSpace: CGFloat = screen.auxiliaryTopRightArea?.width {
            
            let width = (screen.frame.width - topLeftSpace - topRightSpace) + 16
            return width
        }
        
        // Fallback
        return 200
    }
    
    func getMenuBarHeight(for screen: NSScreen? = NSScreen.main) -> CGFloat {
        guard let screen = screen else { return 0 }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // The difference between the full screen height and the visible height
        // is the menu bar height (plus maybe the dock if it's on top).
        return screenFrame.height - visibleFrame.height
    }
    
    func getNotchHeight() -> CGFloat {
        if let screen = DisplayManager.shared.selectedScreen {
            let safeAreaInsets = screen.safeAreaInsets
            let calculatedHeight = safeAreaInsets.top
            
            /// Only return calculated height if it is greater than 0
            if calculatedHeight > 0 {
                return calculatedHeight
            }
        }
        
        /// If no screen is selected or height is 0, return fallback height
        let fallbackHeight = getMenuBarHeight()
        /// Make sure fallback height is greater than 0 or go to the fallback 40
        return fallbackHeight > 0 ? fallbackHeight : 40
    }
}

extension ScrollManager {
    
    /// Function To Peek Open the Notch to the set amount or a default amount of 50
    internal func peekOpen(withHeight: CGFloat = 50) {
        if isPeekingOpen { return }
        isPeekingOpen = true
        defer { isPeekingOpen = false }
        
        let targetWidth = self.getNotchWidth() + 70
        let targetHeight = self.getNotchHeight() + withHeight
        
        /// Peek Open Relates To The Height, so we need to make sure its not the target height already
        guard self.notchSize.height != targetHeight else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            self.notchSize.width = targetWidth
            self.notchSize.height = targetHeight
        }
    }
    
    internal func peekClose() {
        
        if isPeekingClose { return }
        isPeekingClose = true
        defer { isPeekingClose = false }
        
        print("Called Peek Close")
        
        let targetHeight = self.getNotchHeight()
        guard self.notchSize.height != targetHeight else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            self.notchSize.height = targetHeight
        }
    }
    
    /*
     * Function to open the notch fully
     * Anything after this needs to be handled outside
     */
    private func openFullNew() {
        if isOpeningFull { return }
        isOpeningFull = true
        defer { isOpeningFull = false }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            notchSize.width     = settings.notchMaxWidth
            notchSize.height    = self.getMaxPanelHeight()
            self.notchRadius.bottomRadius = 15
        }
        uiManager.panelState = .open
    }
    
    /*
     * Function to close the Notch Fully
     * This represents a Closed fully meaning `no side area`,
     */
    public func closeFull(calledBy: String = "") {

        if isClosingFull { return }
        isClosingFull = true
        defer { isClosingFull = false }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notchSize.width = self.getNotchWidth()
            self.notchSize.height = self.getNotchHeight()
            self.notchRadius.bottomRadius = DEFAULT_BOTTOM_RADIUS
        }
        uiManager.panelState = .closed
    }
    
    /*
     * Function will Expand Width 70+ the getNotchWidth() amount
     * This gives us space to show anything on the left or right side
     * which is managed by the UIManager
     */
    public func expandWidth() {
        
        if isExpandingWidth { return }
        isExpandingWidth = true
        defer { isExpandingWidth = false }
        
        let targetWidth = self.getNotchWidth() + 70
        guard self.notchSize.width != targetWidth else { return }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notchSize.width = targetWidth
        }
    }
}
