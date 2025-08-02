//
//  EventWidget.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/3/25.
//

import SwiftUI
import AppKit

struct EventWidget: View, Widget {
    var name: String = "EventWidget"
    var swiftUIView: AnyView {
        AnyView(self)
    }

    @StateObject private var viewModel = EventWidgetViewModel()
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    var body: some View {
        HStack {
            if viewModel.isCalendarsPermissionsGranted && viewModel.isRemindersPermissionsGranted {
                eventView
            } else {
                permissionsView
            }
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
        /// Determine Width and Height of the given space for this Widget
        .onAppear {
            viewModel.eventWidgetManager.requestPermissionEventsIfNeededOnce { _ in }
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }
        /// This will Let Scrolling be at a threshold
        .onHover { hovering in
            WidgetHoverState.shared.isHoveringOverEvents = hovering
        }
    }
    
    // MARK: - Event View
    private var eventView: some View {
        HStack {
            UserEventView()
            Spacer()
            
            VStack(alignment: .trailing) {
                CalendarScopePicker()
            }
        }
        .environmentObject(viewModel)
    }
    
    // MARK: - Permissions View
    private var permissionsView: some View {
        HStack(alignment: .center) {
            VStack {
                Text("Permissions Not Granted")
                
                Button(action: viewModel.eventWidgetManager.requestPermissions) {
                    Text("Request Permissions")
                }
            }
        }
    }
}
