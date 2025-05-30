//
//  ComfyStepper.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//

import SwiftUI

public struct Style {
    public init(
        height: Double = 34.0,
        labelWidth: Double = 80.0,
        buttonWidth: Double = 48.0,
        buttonPadding: Double = 12.0,
        activeButtonColor: Color = Color.primary,
        inactiveButtonColor: Color = Color.gray,
        titleColor: Color = Color.primary,
        descriptionColor: Color = Color.secondary,
        valueColor: Color = Color.primary
    ) {
        self.height = height
        self.labelWidth = labelWidth
        self.buttonWidth = buttonWidth
        self.buttonPadding = buttonPadding
        self.activeButtonColor = activeButtonColor
        self.inactiveButtonColor = inactiveButtonColor
        self.titleColor = titleColor
        self.descriptionColor = descriptionColor
        self.valueColor = valueColor
    }
    
    var height: Double
    var labelWidth: Double
    
    var buttonWidth: Double
    var buttonPadding: Double
    
    // MARK: - Colors
    var activeButtonColor: Color
    var inactiveButtonColor: Color
    
    var titleColor: Color
    var descriptionColor: Color
    var valueColor: Color
}

public struct ComfyLabeledStepper<T: Comparable & Numeric>: View {

    public init(
        _ title: String,
        value: Binding<T>,
        in range: ClosedRange<T>,
        step: T,
        style: Style = .init()
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.style = style
    }

    @Binding public var value: T

    public var title: String = ""
    public var range: ClosedRange<T>
    public var step: T
    public var style = Style()

    @State private var timer: Timer?

    public var body: some View {
        HStack(alignment: .center) {
            /// Centering the Title and Description
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(style.titleColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    
                    minusButton
                    
                    Divider()
                        .padding([.top, .bottom], 8)
                    
                    displayValue
                    
                    Divider()
                        .padding([.top, .bottom], 8)
                    
                    addButton
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(height: style.height)
            }
            
        }
        .lineLimit(1)
    }
    
    private var displayValue: some View {
        Text("\(value)")
            .foregroundColor(style.valueColor)
            .monospacedDigit()
            .frame(width: style.labelWidth, height: style.height)
    }
    
    private var minusButton: some View {
        /// Minus Button
        Button(action: {
            let newValue = value - step
            if newValue >= range.lowerBound {
                value = newValue
            }
        }) {
            Image(systemName: "minus")
        }
        .frame(width: style.buttonWidth, height: style.height)
        .foregroundColor(
            style.activeButtonColor
        )
        .contentShape(Rectangle())
    }
    
    private var addButton: some View {
        /// Plus Button
        Button(action: {
            let newValue = value + step
            if newValue <= range.upperBound {
                value = newValue
            }
        }) {
            Image(systemName: "plus")
        }
        .frame(width: style.buttonWidth, height: style.height)
        .foregroundColor(
            style.activeButtonColor
        )
        .contentShape(Rectangle())
    }
}
