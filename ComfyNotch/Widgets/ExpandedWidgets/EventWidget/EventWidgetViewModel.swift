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
    
    @Published var isHidingMonth: Bool = false
    @Published var reminders : [EKReminder] = []
    @Published var events    : [EKEvent]    = []
    
    let eventWidgetManager = EventManager.shared
    
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
    
    @MainActor
    public func syncRemindersAndEvents() async{
        print("Synced")
        self.eventWidgetManager.fetchUserReminders()
        self.eventWidgetManager.fetchUserCalendars()
        
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        self.events = eventWidgetManager.getEvents(for: currentDate)
        self.reminders = await eventWidgetManager.getReminders(for: currentDate)
    }
}
