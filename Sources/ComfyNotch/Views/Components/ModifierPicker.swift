//
//  SwiftUIView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/14/25.
//

import SwiftUI

struct ModifierPickerItem: View {
    @State var shortcutName: String
    @Binding var selected: ModifierKey

    init(name: String, selected: Binding<ModifierKey>) {
        self.shortcutName = name
        self._selected = selected
    }
    var body: some View {
        HStack {
            Text(shortcutName)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer(minLength: 16)

            Picker("", selection: $selected) {
                ForEach(ModifierKey.allCases) { key in
                    Text(key.rawValue).tag(key)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

#Preview {
    ModifierPickerItem(name: "Test", selected: .constant(.command))
}
