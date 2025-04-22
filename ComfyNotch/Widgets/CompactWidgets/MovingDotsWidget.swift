import AppKit
import SwiftUI
import Combine

// This view encapsulates the animation for an individual dot.
struct AnimatedDot: View {
    let delay: Double
    let color: Color
    var shouldAnimate: Bool
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .offset(y: shouldAnimate ? (isAnimating ? -5 : 5) : 0)
            .onAppear {
                if shouldAnimate {
                    startAnimation()
                }
            }
            .onChange(of: shouldAnimate) { _, newValue in
                if newValue {
                    startAnimation()
                } else {
                    isAnimating = false
                }
            }
    }

    private func startAnimation() {
        isAnimating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

// The view model for the moving dots.
class MovingDotsViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var playingColor: NSColor = .white

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to changes in the AudioManager's current song text and color.
        AudioManager.shared.$currentSongText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                DispatchQueue.main.async {
                    self?.isPlaying = text != "No Song Playing"
                }
            }
            .store(in: &cancellables)

        AudioManager.shared.$dominantColor
            .receive(on: RunLoop.main)
            .sink { [weak self] color in
                DispatchQueue.main.async {
                    self?.playingColor = color
                }
            }
            .store(in: &cancellables)
    }
}

// The parent view that shows three dots.
// When isPlaying is true, it shows animated dots; otherwise, static dots.
struct MovingDotsView: View, Widget {
    var name: String = "MovingDotsWidget"
    var alignment: WidgetAlignment? = .right
    @ObservedObject var model: MovingDotsViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                AnimatedDot(
                    delay: Double(index) * 0.2,
                    color: Color(model.playingColor),
                    shouldAnimate: model.isPlaying  // controls bounce
                )
            }
        }
        .padding(.trailing, 10)
        // Optionally add an explicit animation for the change in bounce state:
        .animation(.easeInOut(duration: 0.3), value: model.isPlaying)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
