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
    
    internal var eventKitPermissionsRequestedKey: String { "eventKitPermissionsAlreadyRequested" }

    @Published public var isRemindersPermissionsGranted : Bool = false
    @Published public var isCalendarsPermissionsGranted : Bool = false
    
    @Published var reminders : [EKCalendar] = []
    @Published var events    : [EKCalendar]    = []
    
    let calendar = Calendar.current

    /// -- Mark: public API's
    public func fetchUserReminders() {
        guard self.isRemindersPermissionsGranted else { return }
        self.reminders = self.store.calendars(for: .reminder)
    }
    
    public func fetchUserCalendars() {
        guard self.isCalendarsPermissionsGranted else { return }
        self.events = self.store.calendars(for: .event)
    }
    
    // MARK: - Reminders
    /// Function to return the reminders for the given date
    public func getReminders(for date: Date) async -> [EKReminder] {
        guard self.isRemindersPermissionsGranted else { return [] }
        
//        let startOfDay = calendar.startOfDay(for: date)
        
        let predicate = store.predicateForReminders(in: reminders)
        
        let fetched = await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { result in
                cont.resume(returning: result ?? [])
            }
        }
        
        // Filter by due date
        let filtered = fetched.filter { reminder in
            /// Hide completed maybe impliment soon
            //            guard !reminder.isCompleted else { return false }
            /// Return overdue items, maybe impliment soon
            //             return dueDate <= date
            
            guard let dueDate = reminder.dueDateComponents?.date else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
        
        return filtered
    }
    
    // MARK: - Events
    /// Function to get the events for the current date
    public func getEvents(for date: Date) -> [EKEvent] {
        guard self.isCalendarsPermissionsGranted else { return [] }
        
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: events)
        
        let results = store.events(matching: predicate)
        return results
    }
}
