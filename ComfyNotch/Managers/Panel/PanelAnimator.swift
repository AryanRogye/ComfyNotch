//
//  PanelAnimator.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/5/25.
//

import AppKit
import SwiftUI

enum PanelIntent: Equatable {
    case closeTopNotchView
    case openTopNotchView
    case showHoverMenu
}

final class PanelAnimator {
    static let shared = PanelAnimator()
    
    private var panel: NSPanel {
        UIManager.shared.smallPanel
    }
    
    private var lastWasPlaying: String? = nil
    var musicModel: MusicPlayerWidgetModel = .shared
    
    /// For Hover
    private var hoverTimer: Timer?
    private var isHovering = false
    
    private var originalFrame: NSRect = .zero
    private var originalWidth: CGFloat = 0
    private var originalHeight: CGFloat = 0
    
    private var expandedWidth: CGFloat = 0
    private var expandedHeight: CGFloat = 0
    
    private let expansionFactor: CGFloat = 1.5
    private let animationDuration: TimeInterval = 0.2
    
    private var globalHoverMonitor: Any?
    
    private init() {}
    
    func setup() {
        // Safe to access `self.panel` now
        self.originalFrame = panel.frame
        self.originalWidth = originalFrame.width
        self.originalHeight = originalFrame.height
        
        self.expandedWidth = originalWidth
        self.expandedHeight = originalHeight * expansionFactor
    }
    
    deinit {}
    
    
    func startAnimationListeners() {
        print("Starting animation listeners")
        startHoverListener()
        //        startMusicListener()
    }
    
    func stopAnimationListeners() {
        if let monitor = globalHoverMonitor {
            NSEvent.removeMonitor(monitor)
            globalHoverMonitor = nil
        }
        
        hoverTimer?.invalidate()
        hoverTimer = nil
        isHovering = false
    }
    
    
    
    /// Music Listener
    /// MARK: - Music Listener
    /// - Description: Listens for music changes and triggers animations accordingly
    
    func startMusicListener() {
        /// start a timer to listen every 0.5 seconds
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForMusicChange()
        }
    }
    
    private func checkForMusicChange() {
        let currentTrack = musicModel.nowPlayingInfo.trackName
        
        lastWasPlaying = currentTrack
        
        /// check if track name is == No Song Playing
        if currentTrack == "No Song Playing" {
            ScrollHandler.shared.reduceWidth()
        } else {
            ScrollHandler.shared.expandWidth()
        }
    }
    
    /// HOVER LISTENER
    /// Mark: - Hover Listener
    /// - Description: Listens for mouse movement and triggers animations based on hover state
    
    func startHoverListener() {
        globalHoverMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove()
        }
    }
    
    
    private func handleMouseMove() {
        let mouseLocation = NSEvent.mouseLocation
        let panelFrame = panel.frame.insetBy(dx: -10, dy: -10)
        
        if UIManager.shared.panelState != .open {
            if panelFrame.contains(mouseLocation) {
                if musicModel.nowPlayingInfo.trackName == "No Song Playing" { return }
                if !isHovering {
                    isHovering = true
                    startHoverTimer()
                }
            } else if isHovering {
                isHovering = false
                hoverTimer?.invalidate()
                hoverTimer = nil
                PanelAnimationState.shared.currentPanelState = .home
                PanelAnimationState.shared.currentPopInPresentationState = .none
                ScrollHandler.shared.peekClose()
            }
        }
    }
    
    func startHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            defer { self.hoverTimer = nil }
            
            // Add a safety check: only animate if we're not already open
            if UIManager.shared.panelState != .open {
                /// Delay the animation by 0.25 seconds so it doesnt jitter
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if UIManager.shared.panelState != .open {
                            PanelAnimationState.shared.currentPopInPresentationState = .nowPlaying
                            PanelAnimationState.shared.currentPanelState = .popInPresentation
                        }
                    }
                }
                ScrollHandler.shared.peekOpen()
            }
            self.hoverTimer = nil
        }
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }
    
    
    func openingPanelAnimation() {
        ScrollHandler.shared.openFull()
    }
    
    func trigger(_ intent: PanelIntent) {
        switch intent {
        case .openTopNotchView:
            openingPanelAnimation()
        case .closeTopNotchView:
            break
        case .showHoverMenu:
            // Hover menu logic here if needed
            break
        }
    }
}
