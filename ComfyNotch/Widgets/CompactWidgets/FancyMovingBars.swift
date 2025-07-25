//
//  FancyMovingBars.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI
import Combine


// This view encapsulates the animation for an individual bar.
struct AnimatedBar: View {
    let delay: Double
    let dominantColor: NSColor
    var shouldAnimate: Bool
    
    init(delay: Double, dominantColor: NSColor, shouldAnimate: Bool) {
        self.delay = delay
        self.dominantColor = dominantColor
        self.shouldAnimate = shouldAnimate
    }
 
    @ObservedObject private var notchStateManager: NotchStateManager = .shared
    
    @State private var animationHeight: CGFloat = 0
    @State private var animationCancellable: AnyCancellable?
    
    private var animationStiffness: CGFloat = 300
    private var animationDamping: CGFloat = 15
    
    private var minAnimationHeight: CGFloat {
        MusicPlayerWidgetModel.shared.nowPlayingInfo.isPlaying ? 0.1 : 0.2
    }
    
    private let maxAnimationHeight: CGFloat = 0.3

    private var width: CGFloat {
        return (notchStateManager.hoverHandler.scaleHoverOverLeftItems || notchStateManager.hoverHandler.isHoveringOverNotch) ? 3.0 : 2.5
    }
    
    private var scale: CGFloat {
        return (notchStateManager.hoverHandler.scaleHoverOverLeftItems || notchStateManager.hoverHandler.isHoveringOverNotch) ? 1.10 : 1
    }
    
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: dominantColor).opacity(0.5))
            .frame(width: width, height: min(15, 25 * animationHeight))
            .cornerRadius(30)
            .scaleEffect(scale)
            .animation(
                .interpolatingSpring(stiffness: animationStiffness, damping: animationDamping),
                value: (notchStateManager.hoverHandler.scaleHoverOverLeftItems || notchStateManager.hoverHandler.isHoveringOverNotch)
            )
            .onAppear {
                startLoopingAnimation()
                
                animationHeight = minAnimationHeight
            }
            .onChange(of: shouldAnimate) { _, _ in
                startLoopingAnimation()
            }
            .onDisappear {
                animationCancellable?.cancel()
            }
    }
    
    private func startLoopingAnimation() {
        animationCancellable?.cancel()
        
        guard shouldAnimate else {
            withAnimation(.easeOut(duration: 0.3)) {
                animationHeight = minAnimationHeight
            }
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
            animationCancellable = timer.sink { _ in
                withAnimation(.easeInOut(duration: 0.6)) {
                    animationHeight = Double.random(in: minAnimationHeight...maxAnimationHeight)
                }
            }
        }
    }
}

// The parent view that shows animated bars.
// When isPlaying is true, it shows animated bars; otherwise, static bars.
struct FancyMovingBars: Widget, View {
    
    var name: String = "MovingBars"
    var alignment: WidgetAlignment? = .right
    @ObservedObject private var music: MusicPlayerWidgetModel = .shared
    @ObservedObject private var notchStateManager: NotchStateManager = .shared
    var applyNoPadding: Bool = false
    
    /// Padding of 4-2 range pushes it to the left, that way when we hover of the left side,
    /// it pops OUT to the right, making it look like its cool yk
    private var paddingTrailing: CGFloat {
        return (notchStateManager.hoverHandler.scaleHoverOverLeftItems || notchStateManager.hoverHandler.isHoveringOverNotch) ? 6 : 8
    }
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                AnimatedBar(
                    delay: Double(index) * 0.1,
                    dominantColor: music.nowPlayingInfo.dominantColor,
                    shouldAnimate: music.nowPlayingInfo.isPlaying
                )
            }
        }
        .padding(.trailing, applyNoPadding ? 0 : paddingTrailing)
        .padding(.top, applyNoPadding ? 0 : 4)
        // Optionally add an explicit animation for the change in animation state:
        .animation(.easeInOut(duration: 0.3), value: music.nowPlayingInfo.isPlaying)
    }
}
