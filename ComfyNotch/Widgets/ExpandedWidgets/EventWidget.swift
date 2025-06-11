//
//  EventWidget.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/3/25.
//

import SwiftUI
import ComfyCalendar
import AppKit

final class WidgetHoverState: ObservableObject {
    static let shared = WidgetHoverState()
    @Published var isHoveringOverEventWidget: Bool = false
}

struct EventWidget: View, Widget {
    var name: String = "EventWidget"
    @ObservedObject private var model : EventManager = .shared
    @ObservedObject private var hoverState = WidgetHoverState.shared
    
    let pickerValues = ["Daily", "Weekly", "Monthly"]
    
    @State private var selection = "Monthly"
    @State private var selectedCalendarViewOption: ComfyCalendarOptions = .showMonthly
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ViewBuilder
    func pickerContent() -> some View {
        ForEach(pickerValues, id: \.self) {
            Text($0)
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                Picker("",selection: $selection) {
                    pickerContent()
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(height: 22)
                .padding(.top, 2)
                
                ComfyCalendarView(eventStore: $model.store,
                                  calendars: $model.calendars,
                                  reminders: $model.reminders,
                                  with: $selectedCalendarViewOption
                    )
                .frame(maxWidth: .infinity, maxHeight: 100)
                
                Spacer()
            }
//            VStack {
//                HStack {
//                    ScrollView {
//                        ForEach(model.reminders, id: \.self) { reminder in
//                            HStack {
//                                Text(reminder.title)
//                                Spacer()
//                                Button(action: {
//                                    model.removeUserReminders(for: reminder)
//                                } ) {
//                                    Image(systemName: "trash")
//                                        .resizable()
//                                        .frame(width: 16, height: 16)
//                                }
//                            }
//                        }
//                    }
//                    Spacer()
//                    ScrollView {
//                        ForEach(model.calendars, id: \.self) { calendar in
//                            HStack {
//                                Text(calendar.title)
//                                Spacer()
//                                Button(action: {
//                                    
//                                } ) {
//                                    Image(systemName: "trash")
//                                        .resizable()
//                                        .frame(width: 16, height: 16)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            model.fetchUserReminders()
            model.fetchUserCalendars()
        }
        .onHover { hovering in
            hoverState.isHoveringOverEventWidget = hovering
        }
        .onChange(of: selection) { _, newValue in
            if selection == "Daily" {
                selectedCalendarViewOption = .showDaily
            } else if selection == "Weekly" {
                selectedCalendarViewOption = .showWeekly
            } else if selection == "Monthly" {
                selectedCalendarViewOption = .showMonthly
            }
        }
    }
}
