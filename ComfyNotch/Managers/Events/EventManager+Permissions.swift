//
//  EventManager+Permissions.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import EventKit
import Foundation
import AppKit

extension EventManager {
    
    func requestPermissions() {
        clearKeyForPermissions()
        requestPermissionEventsIfNeededOnce { _ in }
    }

    // MARK: - Request Permissions if Needed
    
    /// function is marked with completion because there are cases when we wanna run certain things ONLY once this is ran
    /// regardless of it passing/failing
    func requestPermissionEventsIfNeededOnce(completion: @escaping (Bool) -> Void) {
        let alreadyRequested = UserDefaults.standard.bool(forKey: eventKitPermissionsRequestedKey)
        
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        let hasEventAccess = eventStatus == .fullAccess
        let hasReminderAccess = reminderStatus == .fullAccess || reminderStatus == .authorized

        // Already prompted before — don’t ask again
        if alreadyRequested && hasEventAccess && hasReminderAccess {
            isCalendarsPermissionsGranted = true
            isRemindersPermissionsGranted = true
            completion(true)
            return
        }
        
        // Mark as requested
        UserDefaults.standard.set(true, forKey: eventKitPermissionsRequestedKey)
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        let group = DispatchGroup()
        var calendarGranted = hasEventAccess
        var reminderGranted = hasReminderAccess
        
        /// Check Calendar Status First
        if !hasEventAccess {
            group.enter()
            requestAccessToCalendar { granted in
                self.isCalendarsPermissionsGranted = granted
                calendarGranted = granted
                group.leave()
            }
        }
        
        /// Check Reminder Status Next
        if !hasReminderAccess {
            group.enter()
            requestAccessToReminders { granted in
                self.isRemindersPermissionsGranted = granted
                reminderGranted = granted
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            NSApp.setActivationPolicy(.accessory)
            
            /// Update
            self.isCalendarsPermissionsGranted = calendarGranted
            self.isRemindersPermissionsGranted = reminderGranted
            
            /// Let The App Continue Onwards
            completion(true)
        }
    }
    
    // MARK: - Clear Key For Permissions
    private func clearKeyForPermissions() {
        UserDefaults.standard.removeObject(forKey: eventKitPermissionsRequestedKey)
    }
    
    // MARK: - Request Access To Calendar
    public func requestAccessToCalendar(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToEvents { granted, error in
            if let error = error {
                debugLog("Error requesting access to calendar: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    // MARK: - Request Access To Reminders
    internal func requestAccessToReminders(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToReminders { granted, error in
            
            if let error = error {
                debugLog("Error requesting access to reminders: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(granted)
        }
    }
}

