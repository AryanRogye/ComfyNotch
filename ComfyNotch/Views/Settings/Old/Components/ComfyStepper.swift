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

public struct ComfyLabeledStepperr<T: Comparable & Numeric>: View {
    
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
    @State private var isEditingValue: Bool = false
    @State private var textFieldValue: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showHint: Bool = false
    @State private var hoverSessionID = UUID()
    @State private var hoverTimer: Timer?
    
    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        return f
    }
    
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                /// Centering the Title and Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(style.titleColor)
                        .font(.system(.body, design: .default))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                
                HStack(spacing: 0) {
                    minusButton
                    
                    Divider()
                        .frame(height: style.height - 16)
                    
                    displayValue
                    
                    Divider()
                        .frame(height: style.height - 16)
                    
                    addButton
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(height: style.height)
            }
            .lineLimit(1)
            
            if showHint {
                Group {
                    if isEditingValue {
                        Text("Make Sure To Press [Enter] To Save Changes")
                    } else {
                        Text("Double Click To Edit")
                    }
                }
                .foregroundColor(style.descriptionColor)
                .font(.system(.caption, design: .default))
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onHover { hovering in
            if hovering {
                // new hover session
                let newID = UUID()
                hoverSessionID = newID
                
                hoverTimer?.invalidate()
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    if hoverSessionID == newID {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showHint = true
                        }
                    }
                }
            } else {
                hoverTimer?.invalidate()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showHint = false
                }
            }
        }
    }
    
    private var displayValue: some View {
        VStack {
            if isEditingValue {
                TextField("", text: $textFieldValue)
                    .foregroundColor(style.valueColor)
                    .font(.system(.body, design: .monospaced))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .frame(width: style.labelWidth, height: style.height)
                    .background(Color.clear)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        commitTextFieldValue()
                    }
                    .onChange(of: isTextFieldFocused) { _, isFocused in
                        if !isFocused {
                            commitTextFieldValue()
                        }
                    }
                    .onTapGesture {
                        /// Keep Empty
                    }
                    .onAppear {
                        textFieldValue = formatValue(value)
                    }
            } else {
                Button(action: {
                    isEditingValue = true
                }) {
                    Text("\(value)")
                        .foregroundColor(style.valueColor)
                        .font(.system(.body, design: .monospaced)) // force match
                        .monospacedDigit()
                        .frame(width: style.labelWidth, height: style.height)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(.plain)
            }
        }
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
    
    private func commitTextFieldValue() {
        if let newValue = parseValue(from: textFieldValue) {
            print("Value Is Set to \(newValue)")
            value = clampValue(newValue)
        }
        isEditingValue = false
        isTextFieldFocused = false
    }
    
    private func clampValue(_ newValue: T) -> T {
        if newValue < range.lowerBound {
            return range.lowerBound
        } else if newValue > range.upperBound {
            return range.upperBound
        }
        return newValue
    }
    
    private func formatValue(_ value: T) -> String {
        return String(describing: value)
    }
    
    private func parseValue(from string: String) -> T? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        
        if let number = formatter.number(from: string) {
            //            print("Parsed '\(string)' as \(String(describing: number))")
            return convertNSNumber(number, to: T.self)
        }
        
        return nil
    }
    
    private func convertNSNumber<U: Numeric>(_ number: NSNumber, to type: U.Type) -> U? {
        if let value = number as? U {
            return value
        }
        
        switch U.self {
        case is Int.Type:    return Int(number.intValue) as? U
        case is Double.Type: return number.doubleValue as? U
        case is Float.Type:  return number.floatValue as? U
        case is Int8.Type:   return Int8(number.int8Value) as? U
        case is Int16.Type:  return Int16(number.int16Value) as? U
        case is Int32.Type:  return Int32(number.int32Value) as? U
        case is Int64.Type:  return Int64(number.int64Value) as? U
        case is UInt.Type:   return UInt(number.uintValue) as? U
        case is UInt8.Type:  return UInt8(number.uint8Value) as? U
        case is UInt16.Type: return UInt16(number.uint16Value) as? U
        case is UInt32.Type: return UInt32(number.uint32Value) as? U
        case is UInt64.Type: return UInt64(number.uint64Value) as? U
        default:
            return nil
        }
    }
}
