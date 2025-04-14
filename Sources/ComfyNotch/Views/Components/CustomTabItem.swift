//
//  File.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/14/25.
//

import Foundation
import SwiftUI

struct CustomTabItem: View {

    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(
        icon: String,
        title: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                /// The Icons Image
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
                /// Title
                Text(title)
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 8) {
        CustomTabItem(icon: "gearshape", title: "Settings", isSelected: true) {}
        CustomTabItem(icon: "keyboard", title: "Shortcut", isSelected: false) {}
    }
    .padding()
    .frame(width: 200)
}
