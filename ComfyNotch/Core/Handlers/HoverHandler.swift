//
//  HoverHandler.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/21/25.
//

import Combine
import SwiftUI

enum HoverTarget: String, Codable, CaseIterable, Identifiable {
    case none
    case album
    var id: String { rawValue }
}

extension HoverTarget {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .album: return "Album Image"
        }
    }
}

final class HoverHandler: ObservableObject {
    
    @Published var isHoveringOverPlayPause: Bool = false
    @Published var isHoveringOverLeft: Bool = false
    @Published var isHoveringOverPopin: Bool = false
    
    /// Tells other views that we can now scale
    @Published var scaleHoverOverLeftItems: Bool = false
    @Published var usedButtonToOpen = false
    
    let uiManager = UIManager.shared
    
    /// Used when hovering, around 0.2 seconds after is the hover triggered
    private var hoverTimer: Timer?
    /// Used by the cancel or the "schedule" this will stop the hover
    private var hoverResetTimer: Timer?
    private var invalidateTime: CGFloat {
        settings.enableButtonsOnHover ? 1.0 : 0.3
    }

    private var cancellables = Set<AnyCancellable>()
    private let settings = SettingsModel.shared
    
    
    init() {
        debugLog("Initialize Invalidate Time: \(invalidateTime)", from: .hover)
    }
    
    deinit {
        hoverTimer?.invalidate()
        hoverResetTimer?.invalidate()
    }
    
    private func scheduleHoverResetWithDelay(target: NotchStateManager) {
        hoverResetTimer?.invalidate()
        debugLog("Scheduling Hover Reset With Delay With: \(invalidateTime)", from: .hover)
        hoverResetTimer = Timer.scheduledTimer(withTimeInterval: invalidateTime, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if UIManager.shared.panelState != .closed { return }
            if self.isHoveringOverPopin {
                debugLog("Returned Cuz of Hovering on PopIn", from: .hover)
                return
            }
            if self.isHoveringOverLeft {
                debugLog("[WARNING] Returned Cuz of Hovering on Panel", from: .hover)
                return
            }
            
            DispatchQueue.main.async {
                target.currentPanelState = .home
                target.currentPopInPresentationState = .none
            }
            self.scaleHoverOverLeftItems = false
            DispatchQueue.main.async {
                NotchStateManager.shared.peekClose()
            }
        }
    }
    
    /// This is set inside the Main/ComfyNotchView <- this is important that this is set if hovering should work on the
    /// album
    public func bindHoveringOverLeft(for target: NotchStateManager) {
        /// This works ONLY if the enableButtonsOnHover is true, on a change we will call this, inside we also
        /// validate this with a if self.isHoveringOverPopin or else it returns, so thats why on change we always call it
        $isHoveringOverPopin
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !settings.enableButtonsOnHover { return }
                scheduleHoverResetWithDelay(target: target)
            }
            .store(in: &cancellables)
        
        $isHoveringOverLeft
            .sink { [weak self] hovering in
                guard let self = self else { return }
                /// This is set inside the settings model, the user can pick between the album or the whole panel
                if settings.hoverTargetMode != .album { return }
                /// if is hovering over the left side
                if hovering {
                    /// We do not wanto to do any hover logic if the panel is already open or any other state which is not closed
                    if UIManager.shared.panelState != .closed { return }
                    
                    self.hoverTimer?.invalidate()
                    self.hoverResetTimer?.invalidate() // Cancel any pending reset
                    
                    self.hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        
                        if !self.isHoveringOverLeft { return }
                        
                        /// This will trigger once the panel is opened, 0.25 is a good spot, but i found that
                        /// the notch would get a invalid geometry, this avoids that alltogether
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                /// Check again
                                if !self.isHoveringOverLeft {
                                    if !self.usedButtonToOpen {
                                        print("Detected Weird Panel Behavior, Closing And Returning")
                                        NotchStateManager.shared.peekClose()
                                        return
                                    }
                                }
                                if UIManager.shared.panelState != .open {
                                    target.currentPopInPresentationState = .nowPlaying
                                    target.currentPanelState = .popInPresentation
                                }
                            }
                        }
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)

                        /// Let the notch peek open just a tiny bit, 35
                        DispatchQueue.main.async {
                            NotchStateManager.shared.peekOpen(withHeight: 35)
                        }
                        /// this will let the items on the left and right scale a tiny bit
                        self.scaleHoverOverLeftItems = true
                    }
                    RunLoop.main.add(self.hoverTimer!, forMode: .common)
                    
                } else {
                    if UIManager.shared.panelState != .closed { return }
                    if self.isHoveringOverPopin { return }
                    
                    // Always allow closing, even if panel is open
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    hoverResetTimer?.invalidate()
                    
                    self.scheduleHoverResetWithDelay(target: target)
                }
            }
            .store(in: &cancellables)
    }
}
