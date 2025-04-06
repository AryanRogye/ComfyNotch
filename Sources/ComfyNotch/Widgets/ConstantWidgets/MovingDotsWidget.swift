import AppKit
import SwiftUI
import Combine


// This view encapsulates the animation for an individual dot.
struct AnimatedDot: View {
    let delay: Double
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .offset(y: isAnimating ? -5 : 5)
            .onAppear {
                // Start the animation with a delay.
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever().delay(delay)) {
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
struct MovingDotsView: View, SwiftUIWidget {
    var name: String = "MovingDotsWidget"
    var alignment: WidgetAlignment? = .right
    @ObservedObject var model: MovingDotsViewModel

    var body: some View {
        HStack(spacing: 6) {
            if model.isPlaying {
                ForEach(0..<3) { index in
                    AnimatedDot(delay: Double(index) * 0.2,
                                color: Color(model.playingColor))
                }
            } else {
                // Static dots when not playing
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color(model.playingColor))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.trailing, 10)
    }
     
    var swiftUIView: AnyView {
        AnyView(self)
    }    
}