//
//  BrightnessWatcher.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/24/25.
//

import Foundation
import Combine

final class BrightnessWatcher: ObservableObject {
    static let shared = BrightnessWatcher()

    @Published var currentBrightness: Float = 0.0
    let panelState = PanelAnimationState.shared

    private var previousValue: Float = 0.0
    private var timer: Timer?
    private var dispatchTimer: DispatchSourceTimer?

    private init() {}
    
    func start() {
        BrightnessManager.sharedInstance().start()
        self.currentBrightness = BrightnessManager.sharedInstance().currentBrightness
        self.previousValue = self.currentBrightness

        dispatchTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now(), repeating: .milliseconds(300))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let newVal = BrightnessManager.sharedInstance().currentBrightness
            if abs(newVal - self.previousValue) > 0.01 {
                DispatchQueue.main.async {
                    self.previousValue = newVal
                    self.currentBrightness = newVal
                    print("💡 Brightness changed to: \(newVal)")
                    self.triggerNotch()
                }
            }
        }
        dispatchTimer = timer
        timer.resume()
    }

    func stop() {
        BrightnessManager.sharedInstance().stop()
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }
    
    private var debounceWorkItem: DispatchWorkItem?
    
    private func triggerNotch() {
        print("Notch Triggered")

        debounceWorkItem?.cancel()

        // Show loading instantly
        DispatchQueue.main.async {
            self.panelState.isLoadingPopInPresenter = true
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.openNotch()
            self?.debounceWorkItem = nil
        }
        debounceWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            
            workItem.perform()
            panelState.isLoadingPopInPresenter = false
        }
    }

    private func openNotch() {
        ScrollHandler.shared.peekOpen()
        PanelAnimationState.shared.currentPopInPresentationState = .hud
        PanelAnimationState.shared.currentPanelState = .popInPresentation
    }
}
