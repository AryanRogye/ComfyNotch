import AppKit
import SwiftUI

struct CameraWidgetView : View {
    var body: some View {
        VStack {
            Text("Camera Widget")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            Text("This is a placeholder for the camera feed.")
                .foregroundColor(.white)
                .padding()
        }
        .frame(width: 300, height: 200)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
}

class CameraWidget : Widget {

    var name: String = "CameraWidget"
    var view: NSView

    init() {
        view = NSView()
        view.isHidden = true

    }
 
    func show() {
        view.isHidden = false
    }
    
    func hide() {
        view.isHidden = true
    }
    
    func update() {
    }
}