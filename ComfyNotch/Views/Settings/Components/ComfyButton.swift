//
//  ComfyButton.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/21/25.
//

import SwiftUI

struct ComfyButton: View {
    
    var action: () -> Void
    var title: String
    @Binding var changeColor: Bool
    
    init(title: String, _ changeColor: Binding<Bool>, action: @escaping () -> Void = {}) {
        self.title = title
        self._changeColor = changeColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 1)
                .background {
                    changeColor
                    ? Color.red.opacity(0.2)
                    : Color.green.opacity(0.1)
                }
                .foregroundColor(
                    changeColor
                    ? Color.red
                    : Color.green
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        .controlSize(.small)
        .disabled(!changeColor)
    }
}
