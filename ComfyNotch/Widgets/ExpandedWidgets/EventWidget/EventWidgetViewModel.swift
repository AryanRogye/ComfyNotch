//
//  ViewModel.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import Foundation

final class EventWidgetViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedScope: CalendarScope = .day
    
    @Published var isHidingMonth: Bool = false
    
    public func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: currentDate)
    }
    
    public func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    public func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
