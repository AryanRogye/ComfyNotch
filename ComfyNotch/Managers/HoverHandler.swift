//
//  HoverHandler.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/21/25.
//

import Combine
import SwiftUI

enum HoverTarget: String, Codable, CaseIterable, Identifiable {
    case album
    case panel
    
    var id: String { rawValue }
}

extension HoverTarget {
    var displayName: String {
        switch self {
        case .album: return "Album Image Only"
        case .panel: return "Whole Panel"
        }
    }
}

final class HoverHandler: ObservableObject {
    
    @Published var isHoveringOverPlayPause: Bool = false
    @Published var isHoveringOverLeft: Bool = false
    @Published var scaleHoverOverLeftItems: Bool = false
    
    let uiManager = UIManager.shared
    
    private var hoverTimer: Timer?
    private var hoverResetTimer: Timer?
    private var globalMouseMonitor: Any?
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init() {
        startGlobalMouseTracking()
    }
    
    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hoverTimer?.invalidate()
        hoverResetTimer?.invalidate()
    }
    
    private func startGlobalMouseTracking() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.validateMousePosition()
        }
    }
    
    private func validateMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let panel = uiManager.smallPanel
        
        guard let panelFrame = panel?.frame else { return }
        
        // Check if mouse is actually within the panel bounds
        if !panelFrame.contains(mouseLocation) && isHoveringOverLeft {
            print("Mouse detected outside panel bounds, resetting hover state")
            isHoveringOverLeft = false
        }
    }
    
    /// schedules the hover to reset after a short delay and validates the mouse position
    private func scheduleHoverReset() {
        hoverResetTimer?.invalidate()
        hoverResetTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.validateMousePosition()
        }
    }
    
    /// This is set inside the Main/ComfyNotchView <- this is important that this is set if hovering should work on the
    /// album
    public func bindHoveringOverLeft(for target: PanelAnimationState) {
        $isHoveringOverLeft
            .sink { [weak self] hovering in
                guard let self = self else { return }
                /// This is set inside the settings model, the user can pick between the album or the whole panel
                if SettingsModel.shared.hoverTargetMode != .album { return }
                /// if is hovering over the left side
                if hovering {
                    /// We do not wanto to do any hover logic if the panel is already open or any other state which is not closed
                    if UIManager.shared.panelState != .closed { return }
                    
                    self.hoverTimer?.invalidate()
                    self.hoverResetTimer?.invalidate() // Cancel any pending reset
                    
                    self.hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        
                        self.validateMousePosition()
                        if !self.isHoveringOverLeft { return }
                        
                        /// This will trigger once the panel is opened, 0.25 is a good spot, but i found that
                        /// the notch would get a invalid geometry, this avoids that alltogether
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if UIManager.shared.panelState != .open {
                                    PanelAnimationState.shared.currentPopInPresentationState = .nowPlaying
                                    PanelAnimationState.shared.currentPanelState = .popInPresentation
                                }
                            }
                        }
                        /// Let the notch peek open just a tiny bit
                        ScrollHandler.shared.peekOpen()
                        /// this will let the items on the left and right scale a tiny bit
                        self.scaleHoverOverLeftItems = true
                    }
                    RunLoop.main.add(self.hoverTimer!, forMode: .common)
                    
                } else {
                    if UIManager.shared.panelState != .closed { return }
                    // Always allow closing, even if panel is open
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    hoverResetTimer?.invalidate()
                    
                    target.currentPanelState = .home
                    self.scaleHoverOverLeftItems = false
                    target.currentPopInPresentationState = .none
                    ScrollHandler.shared.peekClose()
                    
                    self.scheduleHoverReset()
                }
            }
            .store(in: &cancellables)
    }
}
