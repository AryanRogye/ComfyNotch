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
    
    @Binding var selectedScope: CalendarScope
    
    @State private var isHovering: Bool = false
    @State private var hoverValue: CalendarScope? = nil
    
    init(selectedScope: Binding<CalendarScope>) {
        _selectedScope = selectedScope
    }

    var body: some View {
        VStack {
            ForEach(CalendarScope.allCases, id: \.self) { value in
                Button(action: {
                    selectedScope = value
                }) {
                    Text(value.rawValue)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background {
                            Circle()
                                .fill(
                                    selectedScope == value
                                    ? Color.blue
                                    : Color.gray
                                )
                        }
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: selectedScope
                        )
                        .scaleEffect(hoverValue == value ? 1.1 : 1)
                }
                .buttonStyle(.plain)
                .onHover {
                    isHovering = $0
                    hoverValue = $0 ? value : nil
                }
            }
            Spacer()
        }
        .frame(maxWidth: 20,maxHeight: .infinity)
    }
}
