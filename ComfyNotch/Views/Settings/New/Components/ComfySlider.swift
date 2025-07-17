//
//  ComfySlider.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ComfySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    
    init(value: Binding<Double>, in range: ClosedRange<Double>, step: Double = 1.0, label: String = "") {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                HStack {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(value))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Rectangle()
                        .fill(Color(NSColor.separatorColor))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    // Progress fill
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: progressWidth(geometry.size.width), height: 3)
                        .cornerRadius(1.5)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        .frame(width: 15, height: 15)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .position(x: thumbPosition(geometry.size.width), y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newValue = valueFromPosition(gesture.location.x, width: geometry.size.width)
                            value = newValue
                        }
                )
            }
            .frame(height: 15)
        }
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * progress
    }
    
    private func thumbPosition(_ totalWidth: CGFloat) -> CGFloat {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * progress
    }
    
    private func valueFromPosition(_ position: CGFloat, width: CGFloat) -> Double {
        let progress = max(0, min(1, position / width))
        let rawValue = range.lowerBound + progress * (range.upperBound - range.lowerBound)
        return round(rawValue / step) * step
    }
}

// MARK: - Convenience initializers for Int values
extension ComfySlider {
    init(value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1, label: String = "") {
        self._value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = Int($0) }
        )
        self.range = Double(range.lowerBound)...Double(range.upperBound)
        self.step = Double(step)
        self.label = label
    }
}
