//
//  EventManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/3/25.
//

import Foundation
import EventKit


class EventManager: ObservableObject {
    static let shared = EventManager()
    @Published var store = EKEventStore()
    
    @Published var calendars: [EKCalendar] = []
    @Published var reminders: [EKReminder] = []
    
    /// -- Mark: public API's
    public func fetchUserReminders() {
        self.requestAccessToReminders() { granted in
            if granted {
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
    }
    
    public func fetchUserCalendars() {
        self.requestAcessToCalendar() { granted in
            if granted {
                print("Request Access to Calendar Granted")
                DispatchQueue.main.async { [weak self] in
                    self?.calendars = self?.store.calendars(for: .event) ?? []
                }
            } else {
                print("Request Access to Calendar Denied")
            }
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
    
    public func requestAcessToCalendar(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToEvents { granted, error in
            if let error = error {
                print("Error requesting access to calendar: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard granted else {
                print("Access to calendar was not granted.")
                completion(false)
                return
            }
            
            completion(true)
        }
    }

    /// -- Mark: private API's
    private func requestAccessToReminders(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToReminders { granted, error in

            if let error = error {
                print("Error requesting access to reminders: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard granted else {
                print("Access to reminders was not granted.")
                completion(false)
                return
            }
            completion(true)
        }
    }
}
