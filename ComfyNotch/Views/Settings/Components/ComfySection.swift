//
//  ComfySection.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/8/25.
//

import SwiftUI

struct ComfySection<Content: View>: View {
    
    var title: String
    var systemImage: String? = nil
    var accentColor: Color = .blue
    var isSub: Bool = false
    
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .foregroundColor(accentColor)
                        .font(.title3)
                }
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, 2)
            
            Rectangle()
                .fill(Color.primary.opacity(isSub ? 0 : 0.1))
                .frame(height: 0.5)
                .padding(.bottom, isSub ? 2 : 0)
            
            content()
        }
        .padding(20)
        .background(
            // Multi-layer background for depth
            ZStack {
                // Base material
                RoundedRectangle(cornerRadius: isSub ? 12 : 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle border
                RoundedRectangle(cornerRadius: isSub ? 12 : 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                
                // Top highlight for glass effect
                RoundedRectangle(cornerRadius: isSub ? 12 : 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 8,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        .padding(.horizontal)
    }
}
