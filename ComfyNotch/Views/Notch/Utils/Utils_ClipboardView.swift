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
            
            prevButton
                .padding(2)
                .padding(.horizontal, 2)
           
            
            editableArea
            
            nextButton
                .padding(2)
                .padding(.horizontal, 2)

        }
        .padding(.top, 2)
        .onChange(of: clipboardManager.clipboardHistory) { _, new in
            // jump to newest when history updates
            currentIndex = new.count - 1
            editorText = currentItem
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
        .onAppear {
            if editorText.isEmpty {
                currentIndex = clipboardManager.clipboardHistory.count - 1
                editorText = currentItem
            }
        }
    }
    
    private var editableArea: some View {
        // Editable, selectable text area
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
                .background(.ultraThinMaterial) // <-- Glassy look
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            TextEditor(text: $editorText)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.primary)
                .background(Color.clear) // <-- Transparent!
                .padding(6)
//                .disabled(true)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var prevButton: some View {
        // Prev button
        Button(action: { move(-1) }) {
            Image(systemName: "chevron.left")
                .foregroundColor(currentIndex > 0 ? .blue : .gray)
        }
        .buttonStyle(.plain)
        .disabled(currentIndex == 0)
    }
    
    private var nextButton: some View {
        // Next button
        Button(action: { move(+1) }) {
            Image(systemName: "chevron.right")
                .foregroundColor(currentIndex < clipboardManager.clipboardHistory.count - 1 ? .blue : .gray)
        }
        .buttonStyle(.plain)
        .disabled(currentIndex >= clipboardManager.clipboardHistory.count - 1)
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
