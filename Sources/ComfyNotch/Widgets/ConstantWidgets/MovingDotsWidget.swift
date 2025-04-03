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
                    .fill(Color(viewModel.playingColor)) // Use the dynamic color from viewModel
                    .frame(width: 6, height: 6)
                    .offset(y: animate ? -5 : 0)
                    .animation(
                        animate ? 
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.2) : 
                            .default,
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
    @Published var playingColor = NSColor.white
}


class MovingDotsWidget: Widget {
    var name: String = "MovingDotsWidget"
    var view: NSView

    private var hostingController: NSHostingController<MovingDotsView>
    private var _alignment: WidgetAlignment = .right

    private var cancellables = Set<AnyCancellable>()

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
        
        // Subscribe to song text changes
        AudioManager.shared.$currentSongText
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
            .store(in: &cancellables)
        
        // Subscribe to color changes
        AudioManager.shared.$dominantColor
            .receive(on: RunLoop.main)
            .sink { [weak self] color in
                DispatchQueue.main.async {
                    self?.viewModel.playingColor = color
                }
            }
            .store(in: &cancellables)
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