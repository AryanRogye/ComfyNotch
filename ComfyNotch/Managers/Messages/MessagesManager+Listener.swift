//
//  MessagesManager+Listener.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/29/25.
//

import Cocoa
import SwiftUI

extension MessagesManager {
    
    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                await self.checkAndFetchIfChanged()
            }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }
    
    private func checkAndFetchIfChanged() async {
        /// Figure out of if we need to update the handles
        let didChange = self.hasChatDBChanged()
        
        /// First message will always be a "fake or a placeholder" message
        if dontShowFirstMessage {
            self.dontShowFirstMessage = false
            return
        }
        
        if didChange {
            await self.fetchAllHandles()
            
            /// Open The Notch If it is not already open
            if UIManager.shared.panelState != .open {
                await self.triggerNotch()
                self.playAudio()
            }
            /// If Open, handle some other way
        }
    }
    
    /// We can trigger the notch here to open
    private func triggerNotch() async {
        pendingNotchOpen?.cancel()
        
        // Check if we should debounce (prevent rapid successive triggers)
        let now = DispatchTime.now()
        let timeSinceLastTrigger = now.uptimeNanoseconds - lastTriggerTime.uptimeNanoseconds
        let minimumInterval: UInt64 = 150_000_000 // 150ms in nanoseconds
        
        if timeSinceLastTrigger < minimumInterval {
            let workItem = DispatchWorkItem { [weak self] in
                self?.executeNotchOpen()
            }
            pendingNotchOpen = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
        } else {
            executeNotchOpen()
        }
        lastTriggerTime = now
    }
    
    private func executeNotchOpen() {
        messageCloseWorkItem?.cancel()
        messageCloseWorkItem = nil
        
        // Set loading state if needed (optional)
        notchStateManager.isLoadingPopInPresenter = true
        
        // Open immediately
        openNotch()
        
        // Clear loading state quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                self.notchStateManager.currentPopInPresentationState = .messages
                self.notchStateManager.currentPanelState = .popInPresentation
            }
            self.notchStateManager.isLoadingPopInPresenter = false
        }
        
        self.restartMessagesPanelTimer()
    }
    
    internal func closeNotch() {
        notchStateManager.currentPopInPresentationState = .none
        notchStateManager.currentPanelState = .home
        ScrollManager.shared.peekClose()
    }
    
    private func openNotch() {
        ScrollManager.shared.peekOpen()
    }
    
    private func hasChatDBChanged() -> Bool {
        guard let dbHandle = self.dbHandle else {
            print("❌ DB not available")
            return false
        }
        
        let timestampInt = Int64(Date().timeIntervalSinceReferenceDate * 1_000_000)
        let hasChanged: Int32 = has_chat_db_changed(dbHandle, timestampInt)
        return hasChanged != 0
    }
}
