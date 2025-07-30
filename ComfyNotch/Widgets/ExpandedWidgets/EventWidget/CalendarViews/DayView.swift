//
//  DayView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import SwiftUI

struct DayView: View {
    
    @EnvironmentObject var viewModel: EventWidgetViewModel
    @State private var scrollTarget: Int = 30
    
    private var visibleDateRange: [Date] {
        let calendar = Calendar.current
        return (-15...15).compactMap {
            calendar.date(byAdding: .day, value: $0, to: viewModel.currentDate)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topMonthRow
            
            Divider()
                .padding(.vertical, 2)
                .foregroundStyle(Color.primary)
            
            pickerView
            
            /// Over here we show information about the currently selected's info
            infoView
            
            Spacer()
        }
        .onAppear {
            Task {
                await viewModel.syncRemindersAndEvents()
            }
        }
    }
    
    private var infoView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            remindersView
            eventsView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var remindersView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Reminders: ")
                    .font(.caption)
                    .frame(alignment: .leading)
                
                Spacer()
                
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 10, height: 10)
            }
            .frame(maxWidth: .infinity)
            
            ForEach(viewModel.reminders, id: \.self) { reminder in
                HStack {
                    Spacer()
                    Text(reminder.title)
                }
            }
        }
    }
    
    private var eventsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Events: ")
                    .font(.caption)
                    .frame(alignment: .leading)
                
                Spacer()
                
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 10, height: 10)
            }
            .frame(maxWidth: .infinity)
            
            ForEach(viewModel.events, id: \.self) { event in
                Text(event.title)
            }
        }
    }
    
    private var topMonthRow: some View {
        VStack(spacing: 0) {
            if !viewModel.isHidingMonth {
                HStack {
                    monthText
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isHidingMonth = true
                        }
                    }) {
                        Text("Hide Month")
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    private var monthText: some View {
        Text(viewModel.formattedMonth(viewModel.currentDate))
            .font(.system(size: 11, weight: .medium, design: .default))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var pickerView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(visibleDateRange.enumerated()), id: \.offset) { index, date in
                        dayView(for: date)
                            .id(index)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(viewModel.currentDate, anchor: .center)
                }
            }
            .onChange(of: viewModel.currentDate) { _, newDate in
                withAnimation {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
    }
    
    private func dayView(for date: Date) -> some View {
        return Button(action: {
            viewModel.currentDate = date
            Task {
                await viewModel.syncRemindersAndEvents()
            }
        }) {
            Text(viewModel.formattedDay(date))
                .font(.system(
                    size: 13,
                    weight: .regular,
                    design: .monospaced
                ))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: 20, height: 20)
                .foregroundColor(viewModel.isToday(date) ? .blue : .white)
        }
        .buttonStyle(.plain)
    }
}
