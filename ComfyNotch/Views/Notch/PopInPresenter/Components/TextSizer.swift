//
//  TickerView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/6/25.
//
import SwiftUI

struct TextSizer: View {
    let text: String
    let font: NSFont
    var onSizeChange: (CGFloat) -> Void

    var body: some View {
        Text(text)
            .font(.init(font))
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: TextWidthPreferenceKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(TextWidthPreferenceKey.self, perform: onSizeChange)
            .hidden()
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
