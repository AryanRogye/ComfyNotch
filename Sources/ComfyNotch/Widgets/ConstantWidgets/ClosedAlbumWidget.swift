import AppKit
import SwiftUI

struct AlbumWidgetView: View {

    var symbolName: String

    var body: some View {
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .padding(5)
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
    }
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

    init() {
        view = NSView()

        hostingController = NSHostingController(rootView: AlbumWidgetView(symbolName: "music.note")) // Use whatever SF Symbol you want

        let hostingView = hostingController.view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view = hostingView
        
        // since this is on close, we start off closed so this is not hidden
        view.isHidden = false
    }

    func update() {
    
    }

    func show() {
        print("Showing ClosedAlbumWidget")
        view.isHidden = false
    }
    func hide() {
        print("Hiding ClosedAlbumWidget")
        view.isHidden = true
    }
}