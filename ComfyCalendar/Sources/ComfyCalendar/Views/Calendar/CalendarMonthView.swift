//
//  CalendarMonthView.swift
//  ComfyCalendar
//
//  Created by Aryan Rogye on 5/5/25.
//

import SwiftUI
import EventKit

public struct CalendarMonthView: View {
    let eventsByDay: [Date: [EKReminder]]
    @Binding var selectedDate: Date?
    
    private let calendar = Calendar.current
    @State var days: [Date] = []
    
    public var body: some View {
        VStack {
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            // Grid of days
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(20), spacing: 10), count: 7),
                spacing: 4
            )
            {
                ForEach(days, id: \.self) { day in
                    let reminders = eventsByDay[calendar.startOfDay(for: day)] ?? []
                    CalendarDayView(date: day,
                                    reminders: reminders,
                                    isSelected: calendar.isDate(day, inSameDayAs: selectedDate ?? Date()),
                                    currentOption: .showMonthly
                    ) {
                        selectedDate = day
                    }
                }
            }
        }
        .onAppear {
            self.days = generateDaysInMonth(for: Date())
        }
    }
    
    func generateDaysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
        let dates = stride(from: firstWeek.start, through: lastWeek.end, by: 60 * 60 * 24).map { $0 }
        return dates
    }
}
