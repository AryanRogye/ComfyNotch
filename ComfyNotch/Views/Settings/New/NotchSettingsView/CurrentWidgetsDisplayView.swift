//
//  CurrentWidgetsDisplayView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct CurrentWidgetsDisplayView: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack {
            notchShapeOpen
        }
    }
    
    
    private var notchContent: some View {
        VStack {
            if settings.selectedWidgets.isEmpty {
                Text("No Widgets Selected")
            } else {
                HStack(spacing: 1) {
                    ForEach(settings.selectedWidgets, id: \.self) { widget in
                        Text(widget)
                        //                        draggableWidgetRow(for: widget)
                        //                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
        }
    }

    private var notchShapeOpen: some View {
        ZStack {
            Image("ScreenBackgroundNotch")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            /// Notch Shape
            VStack(spacing: 0) {}
                .padding(.horizontal, 7)
                .frame(width: 400, height: 140)
            // MARK: - Actual Notch Shape
                .background(
                    ComfyNotchShape(topRadius: 8, bottomRadius: 14)
                        .fill(Color.black)
                )
            /// this is cuz notch is 140 and image is 150, we push it up
                .padding(.top, -10)
        }
    }}
