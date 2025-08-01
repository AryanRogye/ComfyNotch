//
//  MonthView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import SwiftUI

struct MonthView: View {
    
    @EnvironmentObject var viewModel: EventWidgetViewModel
    


    var body: some View {
        VStack {
            topMonthRow
            
            let days = viewModel.daysInMonth(for: viewModel.currentDate)
            let offset = viewModel.startDayOffset(for: viewModel.currentDate)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid (
                    columns: Array(repeating: GridItem(.fixed(15), spacing: 5), count: 7),
                ) {
                    ForEach(0..<offset, id: \.self) { _ in
                        Text("") // just blank
                            .frame(width: 10, height: 10)
                    }
                    
                    // Show actual days
                    ForEach(days, id: \.self) { date in
                        Button(action: {
                            viewModel.currentDate = date
                        }) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(width: 10, height: 10)
                                .background(
                                    Circle()
                                        .fill(viewModel.isToday(date) ? Color.blue : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
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
}
