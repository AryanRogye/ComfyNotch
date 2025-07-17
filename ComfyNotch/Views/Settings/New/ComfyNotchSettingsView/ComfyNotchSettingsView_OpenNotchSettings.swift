//
//  ComfyNotchSettingsView_OpenNotchSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ComfyNotchSettingsView_OpenNotchSettings: View {
    
    
    @State private var leftSpacing: Int = 0
    @State private var rightSpacing: Int = 0
    @State private var topSpacing: Int = 0
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red.opacity(0.5))
                    .frame(width: 2, height: CGFloat(topSpacing))
                HStack {
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: CGFloat(leftSpacing), height: 2)
                    
                    
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
                    
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: CGFloat(rightSpacing), height: 2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(width: 400, height: 150)
            .background(
                ComfyNotchShape(topRadius: 8, bottomRadius: 14)
                    .fill(Color.black)
            )
            
            
            /// Dimensions
            VStack(alignment: .leading) {
                ComfySlider(
                    value: $leftSpacing,
                    in: 0...100,
                    label: "Left Spacing"
                )
                
                ComfySlider(
                    value: $rightSpacing,
                    in: 0...100,
                    label: "Right Spacing"
                )
                
                ComfySlider(
                    value: $topSpacing,
                    in: 0...100,
                    label: "Top Spacing"
                )
            }
            .padding()
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
