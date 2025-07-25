//
//  EventManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/3/25.
//

import Foundation
import EventKit
import AppKit


class EventManager: ObservableObject {
    
    static let shared = EventManager()
    
    @Published var store = EKEventStore()
    
    @Published var calendars: [EKCalendar] = []
    @Published var reminders: [EKReminder] = []
    
    internal var eventKitPermissionsRequestedKey: String { "eventKitPermissionsAlreadyRequested" }

    @Published public var isRemindersPermissionsGranted : Bool = false
    @Published public var isCalendarsPermissionsGranted : Bool = false

    /// -- Mark: public API's
    public func fetchUserReminders() {
        if self.isRemindersPermissionsGranted {
            let predicate: NSPredicate? = self.store.predicateForReminders(in: nil);
            if let aPredicate = predicate {
                self.store.fetchReminders(matching: aPredicate) { reminders in
                    DispatchQueue.main.async { [weak self] in
                        if let reminders = reminders {
                            self?.reminders = reminders
                        }
                    }
                }
            }
        }
    }
    
    public func fetchUserCalendars() {
        if self.isCalendarsPermissionsGranted {
            debugLog("Request Access to Calendar Granted")
            DispatchQueue.main.async { [weak self] in
                self?.calendars = self?.store.calendars(for: .event) ?? []
            }
        } else {
            
        }
    }
    
    public func removeUserReminders(for reminder: EKReminder) {
        DispatchQueue.main.async { [weak self] in
            do {
                try self?.store.remove(reminder, commit: true)
                self?.reminders.removeAll(where: { $0.calendarItemIdentifier == reminder.calendarItemIdentifier })
                debugLog("Removed Reminder \(reminder.title ?? "No Title")")
            } catch {
                debugLog("There was an error removing the reminder")
            }
        }
    }    
}
