//
//  CalendarWeekView.swift
//  ComfyCalendar
//
//  Created by Aryan Rogye on 5/5/25.
//
import SwiftUI
import EventKit

struct CalendarWeekView: View {
    let eventsByDay: [Date: [EKReminder]]
    @Binding var selectedDate: Date?
    
    private let calendar = Calendar.current
    private let currentWeek: [Date]
    
    init(eventsByDay: [Date: [EKReminder]], selectedDate: Binding<Date?>) {
        self.eventsByDay = eventsByDay
        self._selectedDate = selectedDate
        self.currentWeek = Self.generateCurrentWeek()
    }


    var body: some View {
        VStack(spacing: 4) {
            // Weekday headers
            HStack {
                ForEach(currentWeek, id: \.self) { date in
                    let weekday = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                    Text(weekday)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            // Days of week
            HStack(spacing: 8) {
                ForEach(currentWeek, id: \.self) { date in
                    let reminders = eventsByDay[calendar.startOfDay(for: date)] ?? []
                    
                    CalendarDayView(
                        date: date,
                        reminders: reminders,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date()),
                        currentOption: .showWeekly
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    static func generateCurrentWeek() -> [Date] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: Date())?.start else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
}
