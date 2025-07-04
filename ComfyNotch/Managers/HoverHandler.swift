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
    
    @Published var isHoveringOverLeft: Bool = false
    @Published var scaleHoverOverLeftItems: Bool = false
    private var hoverTimer: Timer?
    
    private var cancellables = Set<AnyCancellable>()
    
    public func bindHoveringOverLeft(for target: PanelAnimationState) {
        $isHoveringOverLeft
            .sink { [weak self] hovering in
                guard let self = self else { return }
                if SettingsModel.shared.hoverTargetMode != .album { return }
                
//                print("Is Hover: \(hovering)")
                
                if hovering {
                    if UIManager.shared.panelState != .closed { return }
                    
                    self.hoverTimer?.invalidate()
                    self.hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        
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
                        ScrollHandler.shared.peekOpen()
                        self.scaleHoverOverLeftItems = true
                    }
                    RunLoop.main.add(self.hoverTimer!, forMode: .common)
                    
                } else {
                    
                    if UIManager.shared.panelState != .closed { return }
                    // Always allow closing, even if panel is open
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    target.currentPanelState = .home
                    self.scaleHoverOverLeftItems = false
                    target.currentPopInPresentationState = .none
                    ScrollHandler.shared.peekClose()
                    
                }
            }
            .store(in: &cancellables)
    }
}
