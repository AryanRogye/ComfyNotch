import AppKit
import SwiftUI
import AVFoundation
import Combine

struct CameraWidget : View, SwiftUIWidget {
var name: String = "CameraWidget"

    @ObservedObject private var model = CameraWidgetModel()
    
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
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class CameraWidgetModel: ObservableObject {
    @Published var flipCamera = SettingsModel.shared.isCameraFlipped
    let session = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()

    init() {
        session.sessionPreset = .high

        NotificationCenter.default.publisher(for: .init("FlipCameraChanged"))
            .sink { [weak self] _ in
                self?.flipCamera = SettingsModel.shared.isCameraFlipped
            }
            .store(in: &cancellables)
    }
    
    func startSession() {
        guard !session.isRunning else { return }

        if session.inputs.isEmpty {
            setupCamera()
        }
        session.startRunning()
    }

    func stopSession() {
        session.stopRunning()
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

        if flipCamera {
            previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        }

        view.layer?.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let previewLayer = context.coordinator.previewLayer else { return }
        if flipCamera {
            previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        } else {
            previewLayer.setAffineTransform(.identity)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

