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
    var swiftUIView: AnyView {
        AnyView(self)
    }

    @ObservedObject private var model : EventManager = .shared
    @ObservedObject private var hoverState = WidgetHoverState.shared
    
    @State private var selectedScope: CalendarScope = .day
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    var body: some View {
        HStack {
            if model.isCalendarsPermissionsGranted && model.isRemindersPermissionsGranted {
                eventView
            } else {
                permissionsView
            }
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
        .onAppear {
            model.fetchUserReminders()
            model.fetchUserCalendars()
        }
        /// Determine Width and Height of the given space for this Widget
        .onAppear {
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }
        /// This will Let Scrolling be at a threshold
        .onHover { hovering in
            hoverState.isHoveringOverEventWidget = hovering
        }
    }
    
    // MARK: - Event View
    private var eventView: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .trailing) {
                CalendarScopePicker(selectedScope: $selectedScope)
            }
        }
    }
    
    // MARK: - Permissions View
    private var permissionsView: some View {
        
    }
}
