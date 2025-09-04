//
//  OpenNotchContentDimensionsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct OpenNotchContentDimensionsValues {
    var leftSpacing: Int = 0
    var rightSpacing: Int = 0
    var topSpacing: Int = 0
    var notchMaxWidth: Int = 0
}

struct OpenNotchContentDimensionsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @Binding var v: OpenNotchContentDimensionsValues
    
    init(
        values: Binding<OpenNotchContentDimensionsValues>,
        didChange: Binding<Bool>
    ) {
        self._didChange = didChange
        self._v = values
    }
    
    /// Initial Values
    private var leftSpacingInitialValue: Int {
        Int(settings.quickAccessWidgetDistanceFromLeft)
    }
    private var rightSpacingInitialValue: Int {
        Int(settings.settingsWidgetDistanceFromRight)
    }
    private var topSpacingInitialValue: Int {
        Int(settings.quickAccessWidgetDistanceFromTop)
    }
    private var notchMaxWidthInitialValue: Int {
        Int(settings.notchMaxWidth)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            notchShapeOpen
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider().groupBoxStyle()
            
            dimensionSettings
                .padding(.vertical, 8)
        }
        .onAppear {
            v.leftSpacing = Int(settings.quickAccessWidgetDistanceFromLeft)
            v.rightSpacing = Int(settings.settingsWidgetDistanceFromRight)
            v.topSpacing = Int(settings.quickAccessWidgetDistanceFromTop)
            v.notchMaxWidth = Int(settings.notchMaxWidth)
        }
        .onChange(of: [v.leftSpacing, v.rightSpacing, v.topSpacing, v.notchMaxWidth]) {
            didChange =
            v.leftSpacing != leftSpacingInitialValue
            || v.rightSpacing != rightSpacingInitialValue
            || v.topSpacing != topSpacingInitialValue
            || v.notchMaxWidth != notchMaxWidthInitialValue
        }
    }
    
    // MARK: - Notch Shape
    private var notchShapeOpen: some View {
        ZStack {
            Image("ScreenBackgroundNotch")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            /// Notch Shape
            VStack(spacing: 0) {
                
                /// Showing Of Top Padding Settings
                Rectangle()
                    .fill(Color.red.opacity(0.5))
                    .frame(width: 2, height: CGFloat(v.topSpacing))
                HStack(spacing: 0) {
                    
                    /// Showing Of Left Padding Settings
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: CGFloat(v.leftSpacing), height: 2)
                    
                    
                    /// Both Padding top is set because thats how it is in the notch
                    
                    VStack{}
                        .frame(width: 18, height: 18)
                        .clipShape(
                            Rectangle()
                        )
                        .border(.blue, width: 1)
                    Spacer()
                    VStack{}
                        .frame(width: 18, height: 18)
                        .clipShape(
                            Rectangle()
                        )
                        .border(.red, width: 1)
                    
                    
                    /// Showing Of Right Padding Settings
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: CGFloat(v.rightSpacing), height: 2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 7)
            .frame(width: 400, height: 140)
            // MARK: - Actual Notch Shape
            .background(
                ComfyNotchShape(
                    topRadius: 8, bottomRadius: 14
                )
                    .fill(Color.black)
            )
            /// this is cuz notch is 140 and image is 150, we push it up
        }
    }
    
    // MARK: - Dimension Settings
    private var dimensionSettings: some View {
        VStack(alignment: .leading) {
            ComfySlider(
                value: $v.leftSpacing,
                in: 0...100,
                label: "Left Spacing"
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider().groupBoxStyle()

            ComfySlider(
                value: $v.rightSpacing,
                in: 0...100,
                label: "Right Spacing"
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider().groupBoxStyle()

            ComfySlider(
                value: $v.topSpacing,
                in: 0...Int(ScrollManager.shared.getNotchHeight()),
                label: "Top Spacing"
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider().groupBoxStyle()
            
            ComfySlider(
                value: $v.notchMaxWidth,
                in: Int(settings.MIN_NOTCH_MAX_WIDTH)...Int(settings.MAX_NOTCH_MAX_WIDTH),
                label: "Notch Max Width (While Open)"
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}


// Alternative: Simple dot indicators
struct DotIndicator: View {
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(value/20 + 1, 5), id: \.self) { _ in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: value)
    }
}
