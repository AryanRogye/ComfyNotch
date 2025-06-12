//
//  QuickAccessSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct QuickAccessSettingsView: View {
    
    @ObservedObject var settings: SettingsModel
    @State private var selected: Int = 0
    
    /// Constant Values
    var imageSize: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 0) {
            // 🔒 Lock this at the top
            iconDisplay
                .padding(.bottom, 2)
            
            // 🔽 Make the content scrollable below
            ComfyScrollView {
                VStack {
                    switch selected {
                    case 0: QuickAccessSettingsView_Home()
                    case 1: QuickAccessSettingsView_Messages()
                    case 2: QuickAccessSettingsView_Utils()
                    case 3: QuickAccessSettingsView_FileTray()
                    default: EmptyView()
                    }
                    
                    Spacer(minLength: 80) // Just to give a nice ending space
                }
                .padding()
            }
        }
        .background(Color.clear)
    }
    
    var utilsView: some View {
        VStack {
            Text("Utils Settings")
                .font(.largeTitle)
                .padding(.bottom, 80)
            Spacer()
        }
    }
    
    var iconDisplay: some View {
        HStack(spacing: 16) {
            iconButton("house", isSelected: selected == 0) { selected = 0 }
            iconButton("message", isSelected: selected == 1) { selected = 1 }
            iconButton("wrench.and.screwdriver", isSelected: selected == 2) { selected = 2 }
            iconButton("tray.full", isSelected: selected == 3) { selected = 3 }
        }
        .frame(height: 80)
        .padding(.horizontal)
//        .background(Color.black)
//        .background(.ultraThickMaterial)
        .background(Color.clear)
        .clipShape(RoundedCornersShape(topLeft: 0, topRight: 0, bottomLeft: 20, bottomRight: 20))
    }
    
    @ViewBuilder
    func iconButton(_ systemName: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.interactiveSpring(duration: 0.3)) {
                action()
            }
        }) {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(isSelected ? .blue : .white)
                .padding(12)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
