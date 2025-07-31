//
//  AddEventView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/30/25.
//

import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var viewModel: EventWidgetViewModel
    
    
    @State private var eventTitle: String = ""
    
    @State private var selectedCalendar: String = ""
    @State private var userCalendars : [String] = []
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    @State private var showEventError = false
    @State private var eventError: String? = nil

    var body: some View {
        VStack {
            
            GoBackHome {
                TextField("Title", text: $eventTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                /// We Wanna Choose The Users Calendars
                userCalendarsView
                
                Divider()
                
                startDateView
                
                Divider()
                
                endDateView
                
                Divider()
                
                saveButton
            }
        }
        .onAppear {
            /// Get the users calendars
            userCalendars = viewModel.getUserCalendarNames()
            if !userCalendars.isEmpty {
                selectedCalendar = userCalendars[0]
            }
        }
        .alert(isPresented: $showEventError) {
            Alert(title: Text("Error"),
                  message: Text(eventError ?? ""),
                  dismissButton: .default(Text("OK"), action: {
                        showEventError = false
                        eventError = nil
                  })
            )
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            viewModel.saveEvent(startDate: startDate,
                                 endDate: endDate,
                                 title: eventTitle,
                                 calendarName: selectedCalendar) { errMsg in
                if let err = errMsg {
                    showEventError = true
                    eventError = err
                }
            }
        }) {
            Text("Save")
        }
        .controlSize(.small)
    }
    
    // MARK: - Start Date
    private var startDateView: some View {
        HStack {
            Text("Start Date")
            Spacer()
            DatePicker(
                "",
                selection: $startDate,
                displayedComponents: [.date]
            )
            .controlSize(.small)
        }
    }
    
    // MARK: - End Date
    private var endDateView: some View {
        HStack {
            Text("End Date")
            Spacer()
            DatePicker(
                "",
                selection: $endDate,
                displayedComponents: [.date]
            )
            .controlSize(.small)
        }
    }
    
    // MARK: = User Calendars
    private var userCalendarsView: some View {
        HStack(alignment: .center) {
            Picker("Calendar", selection: $selectedCalendar) {
                ForEach(userCalendars, id: \.self) { calendar in
                    Text(calendar)
                        .id(calendar)
                }
            }
            .controlSize(.small)
        }
    }
}
