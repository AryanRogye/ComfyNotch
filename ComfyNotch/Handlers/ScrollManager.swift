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
    
    let uiManager = UIManager.shared
    var scrollController = ScrollController.new
    
    private var cancellables = Set<AnyCancellable>()
    
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
    
    private var isOpeningFull = false
    private var isClosingFull = false
    private var isExpandingWidth = false
    private var isPeekingOpen = false
    
    private func peekOpenNew(height: CGFloat = 50) {
        if isPeekingOpen { return }
        isPeekingOpen = true
        defer { isPeekingOpen = false }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            self.notchSize.width = self.getNotchWidth() + 70
            self.notchSize.height = self.notchSize.height + height
        }
    }
    
    private func openFullNew() {
        
        if isOpeningFull { return }
        isOpeningFull = true
        defer { isOpeningFull = false }
        
        uiManager.applyOpeningLayout()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            notchSize.width     = 300
            notchSize.height    = self.getMaxPanelHeight()
        }
        uiManager.applyExpandedWidgetLayout()
        uiManager.panelState = .open
    }
    
    private func closeFullNew() {
        
        if isClosingFull { return }
        isClosingFull = true
        defer { isClosingFull = false }

        uiManager.applyOpeningLayout()
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notchSize.width = self.getNotchWidth()
            self.notchSize.height = self.getNotchHeight()
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
        
        uiManager.applyOpeningLayout()
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notchSize.width = self.getNotchWidth() + 70
        }
        uiManager.applyCompactWidgetLayout()
    }
}

extension ScrollManager {
    // MARK: – Helpers
    func getNotchWidth() -> CGFloat {
        guard let screen = DisplayManager.shared.selectedScreen else { return 180 }
        
        if let topLeftSpace: CGFloat = screen.auxiliaryTopLeftArea?.width,
           let topRightSpace: CGFloat = screen.auxiliaryTopRightArea?.width {
            
            let width = (screen.frame.width - topLeftSpace - topRightSpace) + 5
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
