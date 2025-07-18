//
//  BrightnessWatcher.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/24/25.
//

import SwiftUI
import Combine

final class BrightnessWatcher: ObservableObject {
    static let shared = BrightnessWatcher()

    @Published var currentBrightness: Float = 0.0
    let notchStateManager = NotchStateManager.shared
    let popInPresenterCoordinator = PopInPresenter_HUD_Coordinator.shared

    private var previousValue: Float = 0.0
    private var dispatchTimer: DispatchSourceTimer?
    
    // Optimized debouncing
    private var lastTriggerTime: DispatchTime = .now()
    private var pendingNotchOpen: DispatchWorkItem?

    private init() {}
    
    func start() {
        BrightnessManager.sharedInstance().start()
        self.currentBrightness = BrightnessManager.sharedInstance().currentBrightness
        self.previousValue = self.currentBrightness

        dispatchTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive)) // Higher priority
        timer.schedule(deadline: .now(), repeating: .milliseconds(100)) // Faster polling for responsiveness
        timer.setEventHandler { [weak self] in
            self?.checkBrightnessChange()
        }
        dispatchTimer = timer
        timer.resume()
    }

    func stop() {
        BrightnessManager.sharedInstance().stop()
        dispatchTimer?.cancel()
        dispatchTimer = nil
        pendingNotchOpen?.cancel()
        pendingNotchOpen = nil
    }
    
    private func checkBrightnessChange() {
        let newVal = BrightnessManager.sharedInstance().currentBrightness
        
        // Only proceed if there's a meaningful change
        guard abs(newVal - self.previousValue) > 0.01 else { return }
        
        self.previousValue = newVal
        
        // Update UI on main queue but don't block
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentBrightness = newVal
            self.triggerNotchOptimized()
        }
    }
    
    // ZERO-LAG VERSION: No artificial delays
    private func triggerNotchOptimized() {
        
        // Cancel any pending opens
        pendingNotchOpen?.cancel()
        
        // Check if we should debounce (prevent rapid successive triggers)
        let now = DispatchTime.now()
        let timeSinceLastTrigger = now.uptimeNanoseconds - lastTriggerTime.uptimeNanoseconds
        let minimumInterval: UInt64 = 150_000_000 // 150ms in nanoseconds
        
        if timeSinceLastTrigger < minimumInterval {
            // Schedule for later, but much shorter delay
            let workItem = DispatchWorkItem { [weak self] in
                self?.executeNotchOpen()
            }
            pendingNotchOpen = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem) // Only 50ms delay
        } else {
            // Execute immediately
            executeNotchOpen()
        }
        
        lastTriggerTime = now
    }
    
    // INSTANT VERSION: No debouncing at all
    private func triggerNotchInstant() {
        executeNotchOpen()
    }
    
    // Separated execution logic
    private func executeNotchOpen() {
        // Set loading state if needed (optional)
        DispatchQueue.main.async {
            self.notchStateManager.isLoadingPopInPresenter = true
        }
        
        // Open immediately
        openNotch()
        
        
        // Clear loading state quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            
            PopInPresenter_HUD_Coordinator.shared.presentIfAllowed(for: .brightness) {
                withAnimation(.easeOut(duration: 0.2)) {
                    NotchStateManager.shared.currentPopInPresentationState = .hud
                    NotchStateManager.shared.currentPanelState = .popInPresentation
                }
                self.notchStateManager.isLoadingPopInPresenter = false
            }
        }
    }

    private func openNotch() {
        ScrollHandler.shared.peekOpen()
    }
}
