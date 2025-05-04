//
//  EventWidget.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/3/25.
//

import SwiftUI
import AppKit

final class WidgetHoverState: ObservableObject {
    static let shared = WidgetHoverState()
    @Published var isHoveringOverEventWidget: Bool = false
}

struct EventWidget: View, Widget {
    var name: String = "EventWidget"
    @StateObject private var model : EventManager = .shared
    @ObservedObject private var hoverState = WidgetHoverState.shared
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
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
                    Spacer()
                    ScrollView {
                        ForEach(model.calendars, id: \.self) { calendar in
                            HStack {
                                Text(calendar.title)
                                Spacer()
                                Button(action: {
                                    
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            model.fetchUserReminders()
            model.fetchUserCalendars()
        }
        .onHover { hovering in
            hoverState.isHoveringOverEventWidget = hovering
        }
    }
}
