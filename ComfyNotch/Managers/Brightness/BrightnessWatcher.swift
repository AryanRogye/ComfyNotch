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

    private init() {}
    
    func start() {
        BrightnessManager.sharedInstance().start()
        self.currentBrightness = BrightnessManager.sharedInstance().currentBrightness
        self.previousValue = self.currentBrightness

        timer?.invalidate() // Just in case
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let newVal = BrightnessManager.sharedInstance().currentBrightness
            if abs(newVal - self.previousValue) > 0.01 {
                self.previousValue = newVal
                self.currentBrightness = newVal
                print("💡 Brightness changed to: \(newVal)")
                self.triggerNotch()
            }
        }
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
        PanelAnimationState.shared.currentPopInPresentationState = .volume
        PanelAnimationState.shared.currentPanelState = .popInPresentation
    }


    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
}
