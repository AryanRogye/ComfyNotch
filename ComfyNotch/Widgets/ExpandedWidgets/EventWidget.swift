//
//  EventWidget.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/3/25.
//

import SwiftUI

struct EventWidget: View, Widget {
    
    var name: String = "EventWidget"
    @StateObject private var model : EventManager = .shared
    
    var swiftUIView: AnyView {
        AnyView(self)
    }

    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    ForEach(model.reminders, id: \.self) { reminder in
                        HStack {
                            Text(reminder.title)
                            Spacer()
                            Button(action: {
                                model.removeUserReminders(for: reminder)
                            } ) {
                                Image(systemName: "trash")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            model.fetchUserReminders()
        }
    }
}
