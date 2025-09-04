//
//  EventWidgetSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/1/25.
//

import SwiftUI

struct EventWidgetSettingsValues: Equatable {
    var eventWidgetScrollUpThreshold: Int = 3000
}

struct EventWidgetSettings: View {
    
    @Binding var didChange: Bool
    @Binding var values: EventWidgetSettingsValues
    
    @ObservedObject var settings: SettingsModel = .shared
    
    
    @State private var calendarSelected: Bool = true
    
    var body: some View {
        VStack {
            thresholdPicker
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider().groupBoxStyle()
            
            calendarTypePicker
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .onChange(of: values.eventWidgetScrollUpThreshold) {
            didValuesChange()
        }
        .onAppear {
            values.eventWidgetScrollUpThreshold = Int(settings.eventWidgetScrollUpThreshold)
        }
    }
    
    
    /// Visual Only, Coming Soon.....
    // showing a nice visual for just calendar for now
    private var calendarTypePicker: some View {
        HStack {
            ComfyPickerElement(isSelected: calendarSelected, label: "Will show a mix of both Reminders and Calendar events") {
                withAnimation(.spring) {
                    calendarSelected = true
                }
            } content: {
                Text("Calendar")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            ComfyPickerElement(isSelected: !calendarSelected, label: "(Coming Soon...)") {
                withAnimation(.spring) {
                    calendarSelected = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring) {
                        calendarSelected = true
                    }
                }
            } content: {
                Text("Reminders")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Threshold Picker
    private var thresholdPicker: some View {
        ComfySlider(
            value: $values.eventWidgetScrollUpThreshold,
            in: Int(settings.MIN_EVENT_WIDGET_SCROLL_UP_THRESHOLD)...Int(settings.MAX_EVENT_WIDGET_SCROLL_UP_THRESHOLD),
            label: "Scroll Up Threshold"
        )
    }
    
    private func didValuesChange() {
        if values.eventWidgetScrollUpThreshold != Int(settings.eventWidgetScrollUpThreshold) {
            self.didChange = true
        }
    }
}
