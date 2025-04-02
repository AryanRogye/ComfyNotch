import AppKit
import AVFoundation
import Combine

class CameraWidget: Widget {

    var name: String = "CameraWidget"
    var view: NSView
    private var session: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?

    init() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        self.view.isHidden = true
        self.session = AVCaptureSession()
        self.view.wantsLayer = true // Important to enable CALayer support

        setupCamera()
    }
 
    func show() {
        view.isHidden = false
        session.startRunning() // Start the camera feed when showing the widget
    }
    
    func hide() {
        view.isHidden = true
        session.stopRunning() // Stop the camera feed when hiding the widget
    }
    
    func update() {
        // Update logic if needed
    }

    private func setupCamera() {
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("Failed to access camera.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }
        
        // Create the preview layer and add it to your NSView
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        previewLayer?.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        if let layer = view.layer, let previewLayer = previewLayer {
            layer.addSublayer(previewLayer)
        }
    }
}
