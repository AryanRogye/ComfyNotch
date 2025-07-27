//
//  UserEventView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import SwiftUI

struct UserEventView: View {
    
    @EnvironmentObject var viewModel: EventWidgetViewModel
    
    var body: some View {
        VStack {
            switch viewModel.selectedScope {
            case .day:
                DayView()
            case .month:
                MonthView()
            }
        }
        .onAppear {
            /// First Determine What Day it is
        }
    }
}
