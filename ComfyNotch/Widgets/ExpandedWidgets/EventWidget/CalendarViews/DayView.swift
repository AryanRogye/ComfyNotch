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
    
    private var dateRange: [Date] {
        let calendar = Calendar.current
        return (-30...30).compactMap {
            calendar.date(byAdding: .day, value: $0, to: Date())
        }
    }
    
    var body: some View {
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
            }
            
            Divider()
                .padding(.vertical, 2)
                .foregroundStyle(Color.primary)
            
            pickerView
            
            Spacer()
        }
    }
    
    private var monthText: some View {
        Text(viewModel.formattedMonth(viewModel.currentDate))
            .font(.system(size: 13, weight: .medium, design: .default))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var pickerView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(dateRange.enumerated()), id: \.offset) { index, date in
                        dayView(for: date)
                            .id(index)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    if let index = dateRange.firstIndex(where: {
                        Calendar.current.isDate($0, inSameDayAs: viewModel.currentDate)
                    }) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }
    
    private func dayView(for date: Date) -> some View {
        return Button(action: {
            viewModel.currentDate = date
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
