//
//  EventManager+Reminders.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/30/25.
//

import EventKit
import Foundation

extension EventManager {
    func createReminder(title: String, date: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        let reminder = EKReminder(eventStore: self.store)
        reminder.title = title
        reminder.calendar = self.store.defaultCalendarForNewReminders()
        
        let alarm = EKAlarm(absoluteDate: date)
        reminder.addAlarm(alarm)
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        reminder.dueDateComponents = components
        
        do {
            try self.store.save(reminder, commit: true)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
