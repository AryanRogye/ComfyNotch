import AppKit
import SwiftUI
import Combine

// This view encapsulates the animation for an individual dot.
struct AnimatedDot: View {
    let delay: Double
    let color: Color
    var shouldAnimate: Bool
    
    @ObservedObject private var animationState: PanelAnimationState = .shared
    @State private var bounceOffset: CGFloat = 5
    @State private var animationCancellable: AnyCancellable?
    
    private var size: CGFloat {
        return animationState.scaleHoverOverLeftItems ? 7 : 6
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(animationState.scaleHoverOverLeftItems ? 1.15 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animationState.scaleHoverOverLeftItems)
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
            animationCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
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
    
    /// I feel like adding a padding of a 9 makes it pop outwards
    /// doing the same with the left CompactAlbumWidget gives it a more
    /// "Exploding" feeling of going outwards scaling
    private var paddingLeading: CGFloat {
        return animationState.scaleHoverOverLeftItems ? 9 : 10
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
        .padding(.trailing, paddingLeading)
        // Optionally add an explicit animation for the change in bounce state:
        .animation(.easeInOut(duration: 0.3), value: model.nowPlayingInfo.isPlaying)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
