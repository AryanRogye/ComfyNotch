import AppKit
import SwiftUI
import AVFoundation
import Combine

struct CameraWidget: View, Widget {
    
    var name: String = "CameraWidget"
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject private var model = CameraWidgetModel.shared
    @ObservedObject private var settings = SettingsModel.shared
    
    @State var currentZoom: CGFloat = 1.0
    @State private var showOverlay = true
    @State var sessionStarted = false
    @State private var overlayTimer: DispatchWorkItem?
    
    @State private var givenSpace : GivenWidgetSpace = (w: 0, h: 0)
    
    var body: some View {
        ZStack {
            /// Camera Is ALWAYS Shown
            CameraPreviewView(session: model.session, flipCamera: model.flipCamera, zoom: model.zoomScale)
                .frame(maxWidth: givenSpace.w, minHeight: givenSpace.h)
                .cornerRadius(10)
                .clipped()
                .onAppear {
                    // Start session when view appears
                    if !settings.enableCameraOverlay {
                        model.startSession()
                    }
                }
                .onDisappear {
                    // CRITICAL: Clean up timer and session
                    overlayTimer?.cancel()
                    overlayTimer = nil
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
            //            cameraControls
            
            /// Overlay if enabled in settings
            if settings.enableCameraOverlay, showOverlay {
                overlay
            }
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
        .onAppear {
            givenSpace = UIManager.shared.expandedWidgetStore.determineWidthAndHeight()
        }
        // CRITICAL: Store notification observer and clean it up
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadWidgets"))) { _ in
            model.updateFlipState()
        }
    }
    
    private var cameraControls: some View {
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
    }
    
    private var overlay: some View {
        Button(action: startSession) {
            ZStack {
                // Border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.001))
                
                VStack(spacing: 8) {
                    
                    /*
                     * Some Weird Warnings saying:
                     * No symbol named 'web.camera' found in system symbol set
                     * But it still shows up fine, so leaving it here
                     */
                    
                    if #available(macOS 15.0, *) {
                        Image(systemName: "web.camera")
                            .foregroundStyle(.gray)
                            .font(.system(size: givenSpace.w / 9))
                    } else {
                        Image(systemName: "video")
                            .foregroundStyle(.gray)
                            .font(.system(size: givenSpace.w / 9))
                    }
                    Text("Mirror")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding()
                .padding(.horizontal, 32)
            }
            .frame(width: givenSpace.w / 2, height: givenSpace.h / 1.5)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: showOverlay)
    }
    
    private func startSession() {
        guard !sessionStarted else { return }
        sessionStarted = true
        model.startSession()
        showOverlay = false
        
        if settings.enableCameraOverlay && settings.cameraOverlayTimer > 0 {
            // CRITICAL: Cancel existing timer before creating new one
            overlayTimer?.cancel()
            overlayTimer = nil
            
            let workItem = DispatchWorkItem {
                DispatchQueue.main.async {
                    self.showOverlay = true
                    self.sessionStarted = false
                    self.model.stopSession()
                }
            }
            overlayTimer = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(settings.cameraOverlayTimer), execute: workItem)
        }
    }
    
    private var overlay1: some View {
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
            guard !sessionStarted else { return }
            sessionStarted = true
            model.startSession()
            showOverlay = false
            
            if settings.enableCameraOverlay && settings.cameraOverlayTimer > 0 {
                // CRITICAL: Cancel existing timer before creating new one
                overlayTimer?.cancel()
                overlayTimer = nil
                
                let workItem = DispatchWorkItem {
                    DispatchQueue.main.async {
                        self.showOverlay = true
                        self.sessionStarted = false
                        self.model.stopSession()
                    }
                }
                overlayTimer = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(settings.cameraOverlayTimer), execute: workItem)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: showOverlay)
    }
}

class CameraWidgetModel: ObservableObject {
    
    static var shared = CameraWidgetModel()
    
    @Published var flipCamera: Bool
    @Published var zoomScale: CGFloat = 1.0
    
    let session = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()
    
    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)
    private var isSessionSetup = false
    private var currentInput: AVCaptureDeviceInput?
    
    func zoomIn(step: CGFloat = 0.25)  { adjust(by:  step) }
    func zoomOut(step: CGFloat = 0.25) { adjust(by: -step) }
    
    private func adjust(by delta: CGFloat) {
        var next = zoomScale + delta
        next = min(max(1.0, next), 3.0)       // clamp 1×-3×
        zoomScale = next
    }
    
    init() {
        self.flipCamera = SettingsModel.shared.isCameraFlipped
        
        // CRITICAL: Use weak self to prevent retain cycles
        SettingsModel.shared.$isCameraFlipped
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.flipCamera = newValue
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        SettingsModel.shared.$cameraQualitySelection
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.sessionQueue.async { [weak self] in
                    guard let self = self else { return }
                    if self.session.isRunning {
                        self.session.stopRunning()
                    }
                    if self.session.canSetSessionPreset(newValue) {
                        self.session.sessionPreset = newValue
                    }
                    if self.isSessionSetup {
                        self.session.startRunning()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func updateFlipState() {
        let newFlipState = SettingsModel.shared.isCameraFlipped
        if flipCamera != newFlipState {
            flipCamera = newFlipState
            objectWillChange.send()
        }
    }
    
    deinit {
        debugLog("[CameraWidgetModel] Deinit called", from: .widget)
        stopSession()
        cleanupSession()
        // CRITICAL: Cancel all Combine subscriptions
        cancellables.removeAll()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isSessionSetup {
                self.setupCamera()
                self.isSessionSetup = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            debugLog("Failed to access camera.", from: .widget)
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                // CRITICAL: Store reference to input for proper cleanup
                currentInput = input
            }
        } catch {
            debugLog("Error setting up camera input: \(error)", from: .widget)
        }
    }
    
    private func cleanupSession() {
        sessionQueue.sync { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            self.session.beginConfiguration()
            
            // CRITICAL: Remove inputs and outputs properly
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }
            
            self.session.commitConfiguration()
            
            // Clear references
            self.currentInput = nil
            self.isSessionSetup = false
        }
    }
    
    // CRITICAL: Add explicit cleanup method
    func cleanup() {
        stopSession()
        cleanupSession()
        cancellables.removeAll()
    }
}

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let flipCamera: Bool
    let zoom: CGFloat
    
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
        // CRITICAL: Proper cleanup of preview layer
        coordinator.cleanup()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let preview = context.coordinator.previewLayer else { return }
        preview.frame = nsView.bounds
        
        let parentScale = nsView.layer?.value(forKeyPath: "transform.scale.x") as? CGFloat ?? 1
        let zoomScale = (1 / parentScale) * zoom
        
        // Combine zoom and flip transforms
        var transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
        if flipCamera {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        preview.setAffineTransform(transform)
        CATransaction.commit()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        // CRITICAL: Add proper cleanup
        func cleanup() {
            if let previewLayer = previewLayer {
                previewLayer.session = nil
                previewLayer.removeFromSuperlayer()
                self.previewLayer = nil
            }
        }
        
        deinit {
            cleanup()
        }
    }
}
