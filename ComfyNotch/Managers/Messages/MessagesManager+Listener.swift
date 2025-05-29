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
        let didChange = self.hasChatDBChanged()
        if didChange {
            print("DID CHANGE")
            await self.fetchAllHandles()
            
            /// Open The Notch If it is not already open
            if UIManager.shared.panelState != .open {
                await self.triggerNotch()
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
        panelState.isLoadingPopInPresenter = true
        
        // Open immediately
        openNotch()
        
        // Clear loading state quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            panelState.dontShowHoverMenu = true
            withAnimation(.easeOut(duration: 0.2)) {
                PanelAnimationState.shared.currentPopInPresentationState = .messages
                PanelAnimationState.shared.currentPanelState = .popInPresentation
            }
            self.panelState.isLoadingPopInPresenter = false
        }
        
        self.restartMessagesPanelTimer()
    }
    
    internal func closeNotch() {
        PanelAnimationState.shared.currentPopInPresentationState = .none
        PanelAnimationState.shared.currentPanelState = .home
        ScrollHandler.shared.peekClose()
    }
    
    private func openNotch() {
        ScrollHandler.shared.peekOpen()
    }
    
    private func hasChatDBChanged() -> Bool {
        let newMessagesPath = messagesDBPath + "-wal"
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: newMessagesPath),
              let modDate = attrs[.modificationDate] as? Date else {
            return false
        }
        
        if let lastLocalSend = lastLocalSendTimestamp,
           modDate.timeIntervalSince(lastLocalSend) < 1.0 {
            return false
        }
        
        defer { lastKnownModificationDate = modDate }
        return modDate != lastKnownModificationDate
    }
}
