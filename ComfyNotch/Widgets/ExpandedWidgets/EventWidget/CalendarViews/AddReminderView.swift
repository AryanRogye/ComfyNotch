//
//  AddReminderView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/30/25.
//

import SwiftUI

struct AddReminderView: View {
    
    @EnvironmentObject var viewModel: EventWidgetViewModel
    @State var reminderTitle : String = ""
    
    /// Most Likely The Day Will be Today, if Not then we can have the user change it
    @State var dateSelected : Date = Date()
    
    @State private var showReminderError: Bool = false
    @State private var reminderError : String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            /// Go Back and title
            GoBackHome {
                TextField("Title", text: $reminderTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            /// Date Picker
            datePicker
                .padding(.top, 4)
            
            Spacer()
            
            /// Save Button
            saveButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            dateSelected = viewModel.currentDate
        }
        .alert(isPresented: $showReminderError) {
            Alert(
                title: Text("Error"),
                message: Text(reminderError ?? ""),
                dismissButton: .default(Text("OK"), action: {
                    showReminderError = false
                    reminderError = nil
                })
            )
        }
    }
    
    private var saveButton: some View {
        HStack(alignment: .bottom) {
            Button(action: {
                viewModel.saveReminder(for: dateSelected, title: reminderTitle) { errorMsg in
                    if let err = errorMsg {
                        showReminderError = true
                        reminderError = err
                    }
                }
            }) {
                Text("Save")
            }
            .controlSize(.small)
        }
    }
    
    private var datePicker: some View {
        HStack(alignment: .top) {
            DatePicker("Date", selection: $dateSelected, displayedComponents: [.date])
                .labelsHidden()
                .controlSize(.regular)
            Spacer()
        }
    }
}
