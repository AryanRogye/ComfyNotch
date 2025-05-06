//
//  Untitled.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/5/25.
//

import SwiftUI

struct Utils_ClipboardView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var currentIndex: Int = 0
    @State private var editorText: String = ""

    var body: some View {
        HStack(spacing: 2) {
            // Prev button
            Button(action: { move(-1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentIndex > 0 ? .blue : .gray)
            }
            .disabled(currentIndex == 0)

            // Editable, selectable text area
            TextEditor(text: $editorText)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
                .frame(maxWidth: .infinity)
                .onAppear { editorText = currentItem }
                .onChange(of: currentItem) { _, new in editorText = new }

            // Next button
            Button(action: { move(+1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(currentIndex < clipboardManager.clipboardHistory.count - 1 ? .blue : .gray)
            }
            .disabled(currentIndex >= clipboardManager.clipboardHistory.count - 1)
        }
        .padding(.top, 2)
        .onChange(of: clipboardManager.clipboardHistory) { _, new in
            // jump to newest when history updates
            currentIndex = new.count - 1
            editorText = currentItem
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
    }

    private var currentItem: String {
        guard !clipboardManager.clipboardHistory.isEmpty,
              currentIndex >= 0,
              currentIndex < clipboardManager.clipboardHistory.count
        else { return "" }
        return clipboardManager.clipboardHistory[currentIndex]
    }

    private func move(_ offset: Int) {
        let newIndex = currentIndex + offset
        currentIndex = min(max(newIndex, 0), clipboardManager.clipboardHistory.count - 1)
        editorText = currentItem
    }
}
