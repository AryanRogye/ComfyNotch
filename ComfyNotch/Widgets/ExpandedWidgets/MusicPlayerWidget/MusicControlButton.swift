//
//  MusicControlButton.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct MusicControlButton: ButtonStyle {
    
    let size: CGFloat
    let tintColor: NSColor
    
    init(size: CGFloat = 32, tint: NSColor = .white) {
        self.size = size
        self.tintColor = tint
    }
    
    func makeBody(configuration: Configuration) -> some View {
        MusicControlButtonView(
            isPressed: configuration.isPressed,
            size: size,
            tintColor: Color(tintColor)
        ) {
            configuration.label
        }
    }
    
    struct MusicControlButtonView<Label: View>: View {
        @State private var isHovering = false
        let isPressed: Bool
        let size: CGFloat
        let tintColor: Color
        let label: () -> Label
        
        var body: some View {
            ZStack {
                if isHovering {
                    RoundedRectangle(cornerRadius: 10)
                    //                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    tintColor.opacity(isHovering ? 0.25 : 0.15),
                                    tintColor.opacity(isHovering ? 0.15 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                            //                            Circle()
                                .stroke(tintColor.opacity(0.25), lineWidth: 1)
                        )
                        .scaleEffect(isPressed ? 0.95 : (isHovering ? 1.05 : 1.0))
                        .shadow(
                            color: .black.opacity(isHovering ? 0.3 : 0.1),
                            radius: isHovering ? 8 : 4,
                            x: 0,
                            y: isHovering ? 4 : 2
                        )
                }
                label()
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .frame(width: size, height: size)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onHover { hovering in
                isHovering = hovering
            }
        }
    }
}
