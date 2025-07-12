//
//  CalendarDayView.swift
//  ComfyCalendar
//
//  Created by Aryan Rogye on 5/5/25.
//
import SwiftUI
import EventKit

struct CalendarDayView: View {
    let date: Date
    let reminders: [EKReminder]
    let isSelected: Bool
    let currentOption: ComfyCalendarOptions
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                switch currentOption {
                case .showMonthly:
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black)
                        .frame(width: 14, height: 14)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .foregroundColor(Color.white)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                case .showWeekly:
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black)
                        .frame(width: 32, height: 32)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .foregroundColor(Color.white)
                        .font(.system(size: 15, weight: .regular, design: .monospaced))

                case .showDaily:
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black)
                        .frame(width: 48, height: 48)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .foregroundColor(Color.white)
                        .font(.system(size: 24, weight: .regular, design: .monospaced))
                }
                
                if !reminders.isEmpty {
                    Circle()
                        .fill(.pink)
                        .frame(width: 3, height: 3)
                        .offset(y: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
