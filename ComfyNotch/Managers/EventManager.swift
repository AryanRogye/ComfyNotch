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
    var store = EKEventStore()
    
    @Published var calendar: Calendar?
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
    
    private func requestAcessToCalendar() {
        store.requestFullAccessToEvents { granted, error in
        }
    }
}
