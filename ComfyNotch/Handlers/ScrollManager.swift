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
    
    private var artWatcher: AnyCancellable?
    
    let settings = SettingsModel.shared
    
    private var isOpeningFull = false
    private var isClosingFull = false
    private var isExpandingWidth = false
    private var isPeekingOpen = false
    
    init() {
        notchSize = (width: getNotchWidth(), height: getNotchHeight())
        startArtWatch()
    }
    
    public func startArtWatch() {
        guard artWatcher == nil else { return }

        artWatcher = AudioManager.shared.nowPlayingInfo.$artworkImage
            .map { $0 != nil }
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main) // tame flaps
            .receive(on: RunLoop.main)
            .sink { [weak self] hasArt in
                guard let self = self else { return }
                guard !self.isOpeningFull, !self.isClosingFull else { return }
                guard self.uiManager.panelState == .closed else { return }
                
                if hasArt {
                    // you had a 0.4s delay—keep it if you want the animation timing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.uiManager.applyOpeningLayout()
                        self.expandWidth()
                        self.uiManager.applyCompactWidgetLayout()
                    }
                } else {
                    self.closeFull()
                }
            }
    }
    
    public func stopArtWatch() {
        artWatcher?.cancel()
        artWatcher = nil
    }
    
    public func getMaxPanelHeight() -> CGFloat {
        self.getNotchHeight() + 110
    }
    
    public func openFull() {
        stopArtWatch()
        switch scrollController {
        case .new: openFullNew()
        case .old: break
        }
    }
    
    public func closeFull(calledBy: String = "") {
        switch scrollController {
        case .new: closeFullNew()
        case .old: break
        }
        startArtWatch()
    }
    
    public func peekOpen(withHeight: CGFloat = 50) {
        switch scrollController {
        case .new: peekOpenNew(height: withHeight)
        case .old: break
        }
    }
    
    public func peekClose() {
        switch scrollController {
        case .new: closeFull()
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
            print("Notch Width: \(width)")
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
        
        
        if AudioManager.shared.nowPlayingInfo.artworkImage != nil {
            self.uiManager.applyOpeningLayout()
            self.expandWidth()
            self.uiManager.applyCompactWidgetLayout()
        }
    }
    
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
