//
//  DayPicker.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import SwiftUI


struct DayPicker: View {
    
    @State private var currentDate = Date()
    @State private var scrollTarget: Int = 30 // middle index
    
    private var dateRange: [Date] {
        let calendar = Calendar.current
        return (-30...30).compactMap {
            calendar.date(byAdding: .day, value: $0, to: Date())
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: currentDate)
    }
    
    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(dateRange.enumerated()), id: \.element) { index, date in
                            Text(formatted(date))
                                .font(.system(
                                    size: 12,
                                    weight: isToday(date) ? .bold : .regular,
                                    design: .default
                                ))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .foregroundColor(isToday(date) ? .white : .gray)
                                .frame(width: 35, height: 35)
                                .background(
                                    Circle()
                                        .fill(isToday(date) ? Color.blue : Color.clear)
                                )
                                .id(index)
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        currentDate = date
                                        scrollTarget = index
                                        proxy.scrollTo(index, anchor: .center)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, geo.size.width / 2 - 45) // 45 = half the width of one item
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(scrollTarget, anchor: .center)
                    }
                }
            }
            .frame(height: 120)
        }
    }
}
