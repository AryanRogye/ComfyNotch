import SwiftUI
import AppKit
import Combine
import MetalKit



class MetalCoordinator: NSObject, MTKViewDelegate {

    static let shared = MetalCoordinator(device: MTLCreateSystemDefaultDevice()!)

    let pipelineBorder: MTLRenderPipelineState
    let pipelineFull: MTLRenderPipelineState

    var useBorder: Bool = false /// TODO: Replace with enum
    var currentEffect: ShaderEffect = .none {
        didSet {
            print("[MetalCoordinator] currentEffect updated to \(currentEffect)")
        }
    }

    var time: Float = 0
    var shadeColor = SIMD3<Float>(0.2, 0.2, 0.2) // Default comfy fallback
    var pulseStrength: Float = 0 

    // MARK: – Init builds both pipelines from Shaders.metal file
    init(device: MTLDevice) {
        // 1️⃣ load the compiled metallib automatically
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Couldn't find default metallib in app bundle")
        }

        // 2️⃣ build the pipelines
        let descBorder = MTLRenderPipelineDescriptor()
        descBorder.vertexFunction   = library.makeFunction(name: "vertex_main")
        descBorder.fragmentFunction = library.makeFunction(name: "fragment_borderGlow")
        descBorder.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineBorder = try! device.makeRenderPipelineState(descriptor: descBorder)

        let descFull = MTLRenderPipelineDescriptor()
        descFull.vertexFunction   = library.makeFunction(name: "vertex_main")
        descFull.fragmentFunction = library.makeFunction(name: "fragment_fullGlow")
        descFull.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineFull = try! device.makeRenderPipelineState(descriptor: descFull)

        super.init()
    }
    
    convenience override init() {
        fatalError("Use shared instance")
    }

    func updateShade(from nsColor: NSColor, effect: ShaderEffect = .none) {
        let rgb = nsColor.usingColorSpace(.deviceRGB) ?? NSColor.black
        shadeColor = SIMD3<Float>(
            Float(rgb.redComponent),
            Float(rgb.greenComponent),
            Float(rgb.blueComponent)
        )
        self.currentEffect = effect
    }
    
    /// It’s required by the protocol
    /// Dont need it unless we change the size of the view
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    /// Every 60 seconds it tells Metal: "Hey Metal! Here’s what I want to draw next""
    func draw(in view: MTKView) {
        /// Get where to draw. (basically like "give me a fresh canvas")
        guard let passDesc = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,                                // Get the actual texture (image) that will be shown on screen.
            let queue    = view.device?.makeCommandQueue(),                     // Create a command queue (kinda like a todo list for the GPU).
            let buf      = queue.makeCommandBuffer(),                           // Create a command buffer (the specific todo list).
            let enc      = buf.makeRenderCommandEncoder(descriptor: passDesc)   // Create a command encoder (start writing the drawing commands).
            else { return }

        time += 0.03

        var t = time
        enc.setFragmentBytes(&t, length: MemoryLayout<Float>.size, index: 0)

        switch currentEffect {
        case .none:
            enc.endEncoding()
            buf.present(drawable)
            buf.commit()
            return
        case .borderGlow:
            enc.setRenderPipelineState(pipelineBorder)
            var pulseInfo = SIMD4(shadeColor, pulseStrength)
            enc.setFragmentBytes(&pulseInfo, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
        case .fullGlow:
            enc.setRenderPipelineState(pipelineFull)
            var color = shadeColor
            enc.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.size, index: 1)
        }
        // draw quad
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        enc.endEncoding()
        buf.present(drawable)
        buf.commit()

        // decay AFTER commit so this frame uses the original strength
        pulseStrength = max(pulseStrength - 0.003, 0)   // ≈5 s fade‑out
        if pulseStrength == 0 { useBorder = false }     // return to full glow
    }
}


enum ShaderEffect {
    case none
    case borderGlow
    case fullGlow
}

struct MetalBackgroundView: NSViewRepresentable {

    @Binding var effect: ShaderEffect
    @Binding var shade: NSColor

    func makeCoordinator() -> MetalCoordinator {
        MetalCoordinator.shared
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.pipelineBorder.device
        view.delegate = context.coordinator
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 0
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.updateShade(from: shade, effect: effect)
        nsView.setNeedsDisplay(nsView.bounds) // 🔥 force a refresh of the frame
    }
}
