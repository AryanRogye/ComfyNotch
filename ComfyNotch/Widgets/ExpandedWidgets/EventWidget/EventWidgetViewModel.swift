//
//  ViewModel.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import Foundation
import EventKit

final class EventWidgetViewModel: ObservableObject {
    
    @Published var currentDate = Date()
    @Published var selectedScope: CalendarScope = .day
    @Published var dayViewState : DayViewState = .home
    
    @Published var isHidingMonth: Bool = false
    @Published var reminders : [EKReminder] = []
    @Published var events    : [EKEvent]    = []
    
    let eventWidgetManager = EventManager()
    
    // MARK: - Permission Getters
    var isCalendarsPermissionsGranted: Bool {
        eventWidgetManager.isCalendarsPermissionsGranted
    }
    
    var isRemindersPermissionsGranted: Bool {
        eventWidgetManager.isRemindersPermissionsGranted
    }
    
    // MARK: - Date Stuff
    /// function to verify if the given date is the selected "currentDate" in internal
    public func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: currentDate)
    }
    
    public func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    public func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    /// Function to get days in a month
    func daysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        
        let start = monthInterval.start
        let range = calendar.range(of: .day, in: .month, for: date)!
        
        var days: [Date] = []
        
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: start) {
                days.append(dayDate)
            }
        }
        
        return days
    }
    
    func startDayOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstOfMonth = calendar.date(from: components)!
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        return weekday - calendar.firstWeekday // usually 1 (Sunday)
    }
    
    @MainActor
    public func syncRemindersAndEvents() async{
        self.eventWidgetManager.fetchUserReminders()
        self.eventWidgetManager.fetchUserCalendars()
        
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        self.events = eventWidgetManager.getEvents(for: currentDate)
        self.reminders = await eventWidgetManager.getReminders(for: currentDate)
    }
    
    // MARK: - Reminders
    public func saveReminder(for date: Date, title: String, completion: @escaping (String?) -> Void) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            completion("Title is required.")
            return
        }
        
        if trimmedTitle.count > 100 {
            completion("Title is too long.")
            return
        }
        
        self.eventWidgetManager.createReminder(title: trimmedTitle, date: date) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    Task { await self.syncRemindersAndEvents() }
                    self.dayViewState = .home
                case .failure(let failure):
                    completion(failure.localizedDescription)
                    return
                }
            }
        }
    }
    
    // MARK: - Events
    public func getUserCalendarNames() -> [String] {
        Task { @MainActor in
            await syncRemindersAndEvents()
        }
        
        /// Internally stored as events, cuz Eventkits return for .events, so stored For Events
        return eventWidgetManager.events.map { $0.title }
    }
    
    // Saving Logic for the events
    public func saveEvent(startDate: Date,
                           endDate: Date,
                           title: String,
                           calendarName: String,
                           completion: @escaping (String?) -> Void) {
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            completion("Title is required.")
            return
        }

        if trimmedTitle.count > 100 {
            completion("Title is too long.")
            return
        }

        self.eventWidgetManager.createEvent(title: trimmedTitle, startDate: startDate, endDate: endDate, calendarName: calendarName) {  result in
            DispatchQueue.main.async {
                switch result {
                case .success(_): 
                    Task { await self.syncRemindersAndEvents() }
                    self.dayViewState = .home
                case .failure(let failure):
                    completion(failure.localizedDescription)
                    return
                }
            }
        }
    }
}
