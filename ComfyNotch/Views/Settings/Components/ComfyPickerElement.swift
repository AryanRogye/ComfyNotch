//
//  ComfyPickerElement.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/1/25.
//

import SwiftUI

struct ComfyPickerElement<Content: View>: View {
    
    var isSelected: Bool
    var label   : String
    var action  : () -> Void
    var content : () -> Content
    
    init(isSelected: Bool,
         label: String,
         action: @escaping () -> Void,
         @ViewBuilder content: @escaping () -> Content
    ) {
        self.isSelected = isSelected
        self.label = label
        self.action = action
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: isSelected ? 5 : 0)
                    content()
                        .padding(8) // uniform padding inside the box
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.plain)
            
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .default))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
    }
}
