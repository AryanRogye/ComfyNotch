import AppKit
import SwiftUI
import Combine

struct AlbumWidgetView: View {
    var image: NSImage?
    
    var body: some View {
        Group {
            if let nsImage = image {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .cornerRadius(8)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(5)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
        }
    }
}

class AlbumWidgetModel : ObservableObject {
    @Published var image : NSImage?
}


class ClosedAlbumWidget : Widget {

    var name: String = "ClosedAlbumWidget"
    var view: NSView

    private var hostingController: NSHostingController<AlbumWidgetView>
    private var _alignment: WidgetAlignment = .right

    var alignment: WidgetAlignment? {
        get { return _alignment }
        set { 
            if let newValue = newValue {
                _alignment = newValue
                print("Setting alignment to: \(newValue)")
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()


    init() {
        view = NSView()

        hostingController = NSHostingController(rootView: AlbumWidgetView(image: nil)) // Use whatever SF Symbol you want

        let hostingView = hostingController.view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view = hostingView
        
        // since this is on close, we start off closed so this is not hidden
        view.isHidden = false

        AudioManager.shared.$currentArtworkImage
            .receive(on: RunLoop.main)
            .sink { [weak self] newImage in
                self?.updateImage(newImage)
            }
            .store(in: &cancellables)
    }

    private func updateImage(_ image: NSImage?) {
        hostingController.rootView = AlbumWidgetView(image: image)
    }

    func update() {
    
    }

    func show() {
        view.isHidden = false
    }
    func hide() {
        view.isHidden = false
    }
}