import AppKit
import SwiftUI
import Combine


struct MovingDotsView : View {
    @ObservedObject var viewModel: MovingDotsViewModel
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .offset(y: animate ? -5 : 0) // Fixed: neutral position when not animating
                    .animation(
                        animate ? 
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.2) : 
                            .default, // Fixed: use default animation when stopping
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = viewModel.isPlaying
        }
        .onChange(of: viewModel.isPlaying) { newValue in
            animate = newValue
        }
    }
}

class MovingDotsViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
}


class MovingDotsWidget: Widget {
    var name: String = "MovingDotsWidget"
    var view: NSView

    private var hostingController: NSHostingController<MovingDotsView>
    private var _alignment: WidgetAlignment = .right

    private var cancellable: AnyCancellable?
    private var viewModel = MovingDotsViewModel()


    var alignment: WidgetAlignment? {
        get { return _alignment }
        set { 
            if let newValue = newValue {
                _alignment = newValue
                print("Setting alignment to: \(newValue)")
            }
        }
    }

    init() {
        view = NSView()
        hostingController = NSHostingController(rootView: MovingDotsView(viewModel: viewModel))
        let hostingView = hostingController.view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view = hostingView
        view.isHidden = false
        
        // Subscribe to AudioManager's currentSongText changes
        cancellable = AudioManager.shared.$currentSongText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                DispatchQueue.main.async {
                    if text == "No Song Playing" {
                        self?.viewModel.isPlaying = false
                    } else {
                        self?.viewModel.isPlaying = true
                    }
                }
            }
    }

    func update() {
    }

    func show() {
        view.isHidden = false
    }

    func hide() {
        view.isHidden = true
    }
}