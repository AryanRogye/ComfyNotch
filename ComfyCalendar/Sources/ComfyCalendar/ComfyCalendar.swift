import SwiftUI
import EventKit

public enum ComfyCalendarOptions {
    case showMonthly
    case showWeekly
    case showDaily
}

extension Date: @retroactive Identifiable {
    public var id: String { self.description }
}

public struct ComfyCalendarView: View {
    
    @Binding var eventStore: EKEventStore
    @Binding var calendars: [EKCalendar]
    @Binding var reminders: [EKReminder]
    @Binding var options: ComfyCalendarOptions
    
    @State private var selectedDate: Date? = nil
    
    var eventsByDay: [Date: [EKReminder]] {
        Dictionary(grouping: reminders) {
            Calendar.current.startOfDay(for: $0.dueDateComponents?.date ?? Date.distantPast)
        }
    }
    
    public init(eventStore: Binding<EKEventStore>,
                calendars: Binding<[EKCalendar]>,
                reminders: Binding<[EKReminder]>,
                with options: Binding<ComfyCalendarOptions>
    ) {
        _eventStore = eventStore
        _calendars = calendars
        _reminders = reminders
        _options = options
    }
    
    
    public var body: some View {
        ZStack {
            switch options {
            case .showMonthly:
                CalendarMonthView(eventsByDay: eventsByDay, selectedDate: $selectedDate)
            case .showWeekly:
                CalendarWeekView(eventsByDay: eventsByDay, selectedDate: $selectedDate)
            case .showDaily:
                CalendarDayView(date: Date(),
                                reminders: reminders,
                                isSelected: false ,
                                currentOption: .showDaily) {
                    selectedDate = Date()
                }
            }
        }
        .sheet(item: $selectedDate) { date in
            selectedSheet
        }
    }
    
    private var selectedSheet: some View {
        VStack {
            HStack {
                Button(action: {
                    selectedDate = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Selected Date: \(selectedDate?.formatted() ?? "None")")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal)
            .padding(.top, 2)
            
            Divider()
            
            if let date = selectedDate {
                CalendarDayView(date: date,
                                reminders: reminders,
                                isSelected: true,
                                currentOption: options) {
                    selectedDate = nil
                }
            } else {
                Text("No date selected")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

