import AppKit
import SwiftUI
import Combine

// This view encapsulates the animation for an individual dot.
struct AnimatedDot: View {
    let delay: Double
    let color: Color
    var shouldAnimate: Bool
    
    init(delay: Double, color: Color, shouldAnimate: Bool) {
        self.delay = delay
        self.color = color
        self.shouldAnimate = shouldAnimate
    }
    
    @ObservedObject private var animationState: PanelAnimationState = .shared
    @State private var bounceOffset: CGFloat = 5
    @State private var animationCancellable: AnyCancellable?
    
    private var animationStiffness: CGFloat = 300
    private var animationDamping: CGFloat = 15
    
    private var size: CGFloat {
        return animationState.hoverHandler.scaleHoverOverLeftItems ? 7 : 6
    }
    
    private var scale: CGFloat {
        return animationState.hoverHandler.scaleHoverOverLeftItems ? 1.15 : 1
    }
    
    
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(animationState.hoverHandler.scaleHoverOverLeftItems ? 1.10 : 1)
            .animation(
                .interpolatingSpring(stiffness: animationStiffness, damping: animationDamping),
                value: animationState.hoverHandler.scaleHoverOverLeftItems
            )
            .offset(y: shouldAnimate ? bounceOffset : 0)
            .onAppear {
                startLoopingBounce()
            }
            .onChange(of: shouldAnimate) { _, _ in
                startLoopingBounce()
            }
            .onDisappear {
                animationCancellable?.cancel()
            }
    }
    
    private func startLoopingBounce() {
        animationCancellable?.cancel()
        
        guard shouldAnimate else {
            bounceOffset = 0
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            animationCancellable = timer.sink { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    bounceOffset = (bounceOffset == -5) ? 5 : -5
                }
            }
        }
    }
}
// The parent view that shows three dots.
// When isPlaying is true, it shows animated dots; otherwise, static dots.
struct MovingDotsView: View, Widget {
    var name: String = "MovingDotsWidget"
    var alignment: WidgetAlignment? = .right
    @ObservedObject var model: MusicPlayerWidgetModel = .shared
    @ObservedObject private var animationState: PanelAnimationState = .shared
    
    /// Padding of 4-2 range pushes it to the left, that way when we hover of the left side,
    /// it pops OUT to the right, making it look like its cool yk
    private var paddingTrailing: CGFloat {
        return animationState.hoverHandler.scaleHoverOverLeftItems ? 3 : 5
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                AnimatedDot(
                    delay: Double(index) * 0.2,
                    color: Color(model.nowPlayingInfo.dominantColor),
                    shouldAnimate: model.nowPlayingInfo.isPlaying  // controls bounce
                )
            }
        }
        .padding(.trailing, paddingTrailing)
        // Optionally add an explicit animation for the change in bounce state:
        .animation(.easeInOut(duration: 0.3), value: model.nowPlayingInfo.isPlaying)
    }
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
}
