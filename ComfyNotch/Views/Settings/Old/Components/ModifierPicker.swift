//
//  SwiftUIView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/14/25.
//

import SwiftUI

struct ModifierPickerItemm: View {
    @State var shortcutName: String
    @Binding var selectedModifiers: Set<ModifierKey>
    @Binding var key: String?

    init(name: String, selected: Binding<Set<ModifierKey>>, key: Binding<String?>) {
        self.shortcutName = name
        self._selectedModifiers = selected
        self._key = key
    }
    var body: some View {
        VStack {
            HStack {
                /// Show the Shortcut name
                Text(shortcutName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 10)
                displayModifiers()
            }
            HStack {
                displayKeys()
            }
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
    
    @ViewBuilder
    func displayKeys() -> some View {
        Text("Key: ")
            .font(.subheadline)
        TextField("Optional Key", text: Binding(
            get: { key ?? "" },
            set: { newValue in
                key = newValue.isEmpty ? nil : String(newValue.prefix(1)) // Only 1 Char
            }
        ))
        .textFieldStyle(.roundedBorder)
        .frame(width: 100)
    }
    
    @ViewBuilder
    func displayModifiers() -> some View {
        Menu {
            ForEach(ModifierKey.allCases) { key in
                displayModifierButton(for: key)
            }
        } label: {
            HStack {
                if selectedModifiers.isEmpty {
                    Text("Selected Modifier(s)")
                        .foregroundStyle(.secondary)
                }  else {
                    Text(selectedModifiers.map(\.rawValue).joined(separator: " + "))
                        .foregroundStyle(.primary)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: NSColor.controlBackgroundColor))
            )
        }
        .frame(maxWidth: 330)
    }
    
    
    @ViewBuilder
    func displayModifierButton(for key: ModifierKey) -> some View {
        Button {
            toggleModifier(key)
        } label: {
            HStack {
                Text(key.rawValue)
                Spacer()
                if selectedModifiers.contains(key) {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    private func toggleModifier(_ modifier: ModifierKey) {
        if selectedModifiers.contains(modifier) {
            selectedModifiers.remove(modifier)
        } else {
            selectedModifiers.insert(modifier)
        }
    }
}

#Preview {
    ModifierPickerItemm(name: "Test", selected: .constant([.command]), key: .constant("t"))
}
