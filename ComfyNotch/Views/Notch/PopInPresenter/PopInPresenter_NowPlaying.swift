//
//  PopInPresenter_NowPlaying.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/6/25.
//

import SwiftUI

struct NotchLoadingDot: View {
    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 6, height: 6)
            .scaleEffect(1.1)
            .animation(
                Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: UUID() // force the animation
            )
    }
}

struct PopInPresenter_NowPlaying: View {
    
    @ObservedObject var settingsModel: SettingsModel = .shared
    @ObservedObject var musicModel: MusicPlayerWidgetModel = .shared
    @ObservedObject var panelState: PanelAnimationState = .shared
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var animate = false
    
    private var nowPlayingScrollSpeed: Int {
        settingsModel.nowPlayingScrollSpeed
    }
    
    var body: some View {
        ZStack {
            VStack {
                Divider()
                // Use a single GeometryReader to get container width
                GeometryReader { geo in
                    let text = "\(musicModel.nowPlayingInfo.trackName) by \(musicModel.nowPlayingInfo.artistName)"
                    
                    Text(text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(nsColor: musicModel.nowPlayingInfo.dominantColor))
                        .fixedSize(horizontal: true, vertical: false)
                        .measureSize { size in
                            // Only update width if it changed significantly
                            if abs(textWidth - size.width) > 1 {
                                textWidth = size.width
                            }
                            if containerWidth == 0 {
                                containerWidth = geo.size.width
                            }
                        }
                        .offset(x: animate ? -textWidth - 50 : containerWidth)
                        .onChange(of: textWidth) {
                            handleTextWidthChange()
                        }
                }
            }
            .frame(height: 40)
            .clipped()
            .padding(.horizontal, 20)
//            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
        }
    }
    
    func handleTextWidthChange() {
        if !animate && textWidth > 0 && containerWidth > 0 {
            withAnimation(.linear(duration: Double(textWidth) / Double(nowPlayingScrollSpeed)).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

// Helper view modifier to measure view size
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func measureSize(perform action: @escaping (CGSize) -> Void) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}
