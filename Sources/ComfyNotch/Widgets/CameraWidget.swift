import AppKit
import SwiftUI
import AVFoundation
import Combine


struct CameraWidget: View, Widget {
    var name: String = "CameraWidget"
    @StateObject private var model = CameraWidgetModel()
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: model.session, flipCamera: model.flipCamera)
                .cornerRadius(10)
                .onAppear {
                    model.startSession()
                }
                .onDisappear {
                    model.stopSession()
                }
        }
        .background(Color.black)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadWidgets"))) { _ in
            // Force refresh when widgets are reloaded
            model.updateFlipState()
        }
    }
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class CameraWidgetModel: ObservableObject {
    @Published var flipCamera: Bool
    let session = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.flipCamera = SettingsModel.shared.isCameraFlipped
        
        // Listen for settings changes
        SettingsModel.shared.$isCameraFlipped
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if self.flipCamera != newValue {
                    self.flipCamera = newValue
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        // Set up session
        session.sessionPreset = .high
    }
    
    func updateFlipState() {
        let newFlipState = SettingsModel.shared.isCameraFlipped
        if flipCamera != newFlipState {
            flipCamera = newFlipState
            objectWillChange.send()
        }
    }
    
    func startSession() {
        // Run on background thread to avoid UI freezing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            
            if self.session.inputs.isEmpty {
                self.setupCamera()
            }
            
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        // Run on background thread to avoid UI freezing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }
    
    private func setupCamera() {
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
        }
    }
}

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let flipCamera: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        context.coordinator.previewLayer = previewLayer
        view.layer?.addSublayer(previewLayer)
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let previewLayer = context.coordinator.previewLayer else { return }
        
        // Ensure the layer covers the entire view
        previewLayer.frame = nsView.bounds
        
        // Update the flip transform
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            
            if flipCamera {
                previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            } else {
                previewLayer.setAffineTransform(.identity)
            }
            
            CATransaction.commit()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
