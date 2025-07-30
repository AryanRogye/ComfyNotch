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
            
            LazyVGrid (
                columns: Array(repeating: GridItem(.fixed(20), spacing: 10), count: 7),
            ) {
//                ForEach(viewModel)
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
