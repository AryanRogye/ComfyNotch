//
//  ComfySettingsContainer.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ComfySettingsContainer<Content: View, Header: View>: View {
    let content: () -> Content
    let header: () -> Header?
    
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Header?
    ) {
        self.content = content
        self.header = header
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .top) {
                header()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 3)
            .zIndex(1)

            HStack(alignment: .top, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                // Multi-layer background for depth
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                    
                    // Top highlight for glass effect
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 8,
                x: 0,
                y: 2
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
        }
    }
}

extension ComfySettingsContainer where Header == EmptyView {
    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(content: content, header: { EmptyView() })
    }
}
