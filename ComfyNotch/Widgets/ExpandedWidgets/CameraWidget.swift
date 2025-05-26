import AppKit
import SwiftUI
import AVFoundation
import Combine

struct CameraWidget: View, Widget {
    
    var name: String = "CameraWidget"
    
    @StateObject private var model = CameraWidgetModel.shared
    @StateObject private var settings = SettingsModel.shared
    
    @State var currentZoom: CGFloat = 1.0
    @State private var showOverlay = true
    
    var body: some View {
        ZStack {
            /// Camera Is ALWAYS Shown
            CameraPreviewView(session: model.session, flipCamera: model.flipCamera, zoom: model.zoomScale)
                .frame(maxWidth: .infinity, minHeight: 120)
                .cornerRadius(10)
                .clipped()
                .onAppear {
                    if !settings.enableCameraOverlay {
                        model.startSession()
                    }
                }
                .onDisappear {
                    model.stopSession()
                }
                .onChange(of: settings.enableCameraOverlay) { _, newValue in
                    if newValue {
                        showOverlay = true
                        model.stopSession()
                    } else {
                        showOverlay = false
                        model.startSession()
                    }
                }
            
            /// Always Show Users Camera Settings
            HStack {
                Spacer()
                /// We Add A Zoom here
                VStack {
                    Button(action: { model.zoomIn() } ) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 15, height: 15)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { model.zoomOut() } ) {
                        Image(systemName: "minus")
                            .resizable()
                            .frame(width: 15, height: 5)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding([.top, .trailing], 3)
            }
            
            /// Overlay if enabled in settings
            if settings.enableCameraOverlay, showOverlay {
                ZStack {
                    Color.black.opacity(0.6)
                        .blur(radius: 6)
                        .cornerRadius(10)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 30, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("Tap to dismiss overlay")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .onTapGesture {
                    model.startSession()
                    showOverlay = false
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: showOverlay)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadWidgets"))) { _ in
            // Force refresh when widgets are reloaded
            model.updateFlipState()
        }
        .frame(minWidth: 100)
    }
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class CameraWidgetModel: ObservableObject {
    
    static var shared = CameraWidgetModel()
    
    @Published var flipCamera: Bool
    @Published var zoomScale: CGFloat = 1.0
    
    let session = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()

    func zoomIn(step: CGFloat = 0.25)  { adjust(by:  step) }
    func zoomOut(step: CGFloat = 0.25) { adjust(by: -step) }

    private func adjust(by delta: CGFloat) {
        var next = zoomScale + delta
        next = min(max(1.0, next), 3.0)       // clamp 1×-3×
        zoomScale = next
    }
    
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
    
    deinit {
        debugLog("[CameraWidgetModel] Deinit called")
        stopSession()
        cleanupSession()
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
            debugLog("Failed to access camera.")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            debugLog("Error setting up camera input: \(error)")
        }
    }
    
    private func cleanupSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }
            self.session.commitConfiguration()
        }
    }
}

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let flipCamera: Bool
    let zoom: CGFloat            // ← NEW

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill

        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.frame = view.bounds

        context.coordinator.previewLayer = previewLayer
        view.layer?.addSublayer(previewLayer)

        return view
    }
    
    func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        // Remove the preview layer
        if let previewLayer = coordinator.previewLayer {
            previewLayer.removeFromSuperlayer()
            coordinator.previewLayer = nil
        }
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let preview = context.coordinator.previewLayer else { return }

        preview.frame = nsView.bounds

        // cancel any outer panel scale
        let parentScale = nsView.layer?.value(forKeyPath: "transform.scale.x") as? CGFloat ?? 1
        let combined    = (1 / parentScale) * zoom        // <— INCLUDE zoom

        preview.setAffineTransform(CGAffineTransform(scaleX: combined,
                                                     y: combined))
        
//        try? device.lockForConfiguration()
//        device.videoZoomFactor = zoom
//        device.unlockForConfiguration()

        // Flip if needed
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        if flipCamera {
            preview.setAffineTransform(
                preview.affineTransform().scaledBy(x: -1, y: 1)
            )
        }
        CATransaction.commit()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
