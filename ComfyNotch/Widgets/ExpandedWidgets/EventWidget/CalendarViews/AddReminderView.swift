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
    
    var body: some View {
        VStack {
            GoBackHome {
                TextField("Reminder Title", text: $reminderTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                /// Date Picker Here
                DatePicker("", selection: $dateSelected, displayedComponents: [.date])
                    .labelsHidden()
                    .controlSize(.small)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            dateSelected = viewModel.currentDate
        }
    }
}
