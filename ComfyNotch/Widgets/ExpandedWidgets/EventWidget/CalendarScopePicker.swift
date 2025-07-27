//
//  CalendarScopePicker.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import SwiftUI

enum CalendarScope: String, CaseIterable {
    case day    = "D"
    case month  = "M"
}

struct CalendarScopePicker: View {
    @EnvironmentObject var viewModel : EventWidgetViewModel
    
    @State private var isHovering: Bool = false
    @State private var hoverValue: CalendarScope? = nil
    
    var body: some View {
        VStack {
            scopePicker
            
            Spacer()
            
            /// Button to show and hide the month, this is triggered from the DayView
            if viewModel.isHidingMonth {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isHidingMonth = false
                    }
                }) {
                    VStack {
                        Text("Show")
                            .font(.system(size: 9, weight: .regular, design: .default))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 6)
                    }
                    .fixedSize()
                }
                .controlSize(.mini)
                .rotationEffect(.degrees(-90))
            }
            Spacer()
        }
        .frame(maxWidth: 20,maxHeight: .infinity)
    }
    
    private var scopePicker: some View {
        ForEach(CalendarScope.allCases, id: \.self) { value in
            Button(action: {
                viewModel.selectedScope = value
            }) {
                Text(value.rawValue)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background {
                        Circle()
                            .fill(
                                viewModel.selectedScope == value
                                ? Color.blue
                                : Color.gray
                            )
                    }
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: viewModel.selectedScope
                    )
                    .scaleEffect(hoverValue == value ? 1.1 : 1)
            }
            .buttonStyle(.plain)
            .onHover {
                isHovering = $0
                hoverValue = $0 ? value : nil
            }
        }
    }
}
