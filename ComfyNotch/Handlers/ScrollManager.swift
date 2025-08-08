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
    
    private var cancellables = Set<AnyCancellable>()
    
    let settings = SettingsModel.shared
    
    private var isOpeningFull = false
    private var isClosingFull = false
    private var isExpandingWidth = false
    private var isPeekingOpen = false
    
    init() {
        notchSize = (width: getNotchWidth(), height: getNotchHeight())
        
        AudioManager.shared.nowPlayingInfo.$artworkImage
            .sink { [weak self] image in
                guard let self = self else { return }
                if self.isOpeningFull || self.isClosingFull { return }
                
                if image != nil {
                    if self.uiManager.panelState == .closed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.expandWidth()
                        }
                    }
                } else {
                    if self.uiManager.panelState == .closed {
                        self.closeFull()
                    }
                }
            }
            .store(in: &cancellables)
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
    
    public func closeFull() {
        switch scrollController {
        case .new: closeFullNew()
        case .old: break
        }
    }
    
    public func peekOpen(withHeight: CGFloat = 50) {
        print("Called Peek Open")
        switch scrollController {
        case .new: peekOpenNew(height: withHeight)
        case .old: break
        }
    }
    
    public func peekClose() {
        print("Called Peek Close")
        switch scrollController {
        case .new: closeFull()
        case .old: break
        }
    }
    
    public func re_align_notch() {
        switch scrollController {
        case .new: re_align_notch_new()
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
            print("Using \(width)")
            return width
        }
        
        // Fallback
        print("USING FALLBACK")
        return 200
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
        let fallbackHeight = 38.0
        /// Make sure fallback height is greater than 0 or go to the fallback 40
        return fallbackHeight > 0 ? fallbackHeight : 40
    }
}

extension ScrollManager {
    
    /// Function To Peek Open the Notch to the set amount or a default amount of 50
    private func peekOpenNew(height: CGFloat = 50) {
        if isPeekingOpen { return }
        isPeekingOpen = true
        defer { isPeekingOpen = false }
        
        let targetWidth = self.getNotchWidth() + 70
        let targetHeight = self.getNotchHeight() + height
        
        /// Peek Open Relates To The Height, so we need to make sure its not the target height already
        guard self.notchSize.height != targetHeight else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            self.notchSize.width = targetWidth
            self.notchSize.height = targetHeight
        }
    }
    
    /// Function to open the Notch Fully
    private func openFullNew() {
        if isOpeningFull { return }
        isOpeningFull = true
        defer { isOpeningFull = false }
        
        uiManager.applyOpeningLayout()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            notchSize.width     = settings.notchMaxWidth
            notchSize.height    = self.getMaxPanelHeight()
            self.notchRadius.bottomRadius = 15
        }
        uiManager.applyExpandedWidgetLayout()
        uiManager.panelState = .open
    }
    
    /*
     * Function to close the Notch Fully
     * This represents a Closed fully meaning `no side area`,
     * TODO: Once the notch closes, figure out what to do with the closed state
     *       For Example we may want to expand the width of the panel if music is playing etc.
     *       Main point being we have a way to figure out what to do once the notch closes
     */
    private func closeFullNew() {
        
        if isClosingFull { return }
        isClosingFull = true
        defer { isClosingFull = false }
        
        uiManager.applyOpeningLayout()
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notchSize.width = self.getNotchWidth()
            self.notchSize.height = self.getNotchHeight()
            self.notchRadius.bottomRadius = DEFAULT_BOTTOM_RADIUS
        }
        uiManager.panelState = .closed
        
        if AudioManager.shared.nowPlayingInfo.isPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.expandWidth()
            }
        }
    }
    
    private func expandWidth() {
        
        if isExpandingWidth { return }
        isExpandingWidth = true
        defer { isExpandingWidth = false }
        
        let targetWidth = self.getNotchWidth() + 70
        guard self.notchSize.width != targetWidth else { return }
        
        uiManager.applyOpeningLayout()
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notchSize.width = targetWidth
        }
        uiManager.applyCompactWidgetLayout()
    }
    
    private func re_align_notch_new() {
        guard let panel = uiManager.smallPanel else { return }
        guard uiManager.panelState == .closed else { return }
        
        let screen = DisplayManager.shared.selectedScreen!
        let id = screen.displayID
        
        /// we want to look for the screen with the ID cuz the frame is not logging
        /// that its different, I had the resolution 1800x1169 and changed to 1512x982
        /// but the frame was still logging 1800x1169
        
        guard let screen = NSScreen.screens.first(where: {
            $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == id
        }) else {
            debugLog("❌ Could not find screen with displayID \(String(describing: id))", from: .scroll)
            return
        }
        
        DispatchQueue.main.async {
            DisplayManager.shared.selectedScreen = screen
        }
        
        if !panel.frame.equalTo(screen.frame) {
            panel.setFrame(screen.frame, display: true)
        }
    }
}
