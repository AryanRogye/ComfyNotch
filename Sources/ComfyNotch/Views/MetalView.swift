import SwiftUI
import AppKit
import Combine
import MetalKit


enum ShaderEffect {
    case none
    case borderGlow
    case fullGlow
}

class MetalCoordinator: NSObject, MTKViewDelegate {

    static let shared = MetalCoordinator(device: MTLCreateSystemDefaultDevice()!)

    let pipelineBorder: MTLRenderPipelineState
    let pipelineFull: MTLRenderPipelineState

    var useBorder: Bool = false /// TODO: Replace with enum
    var currentEffect: ShaderEffect = .none

    var time: Float = 0
    var shadeColor = SIMD3<Float>(0.2, 0.2, 0.2) // Default comfy fallback
    var pulseStrength: Float = 0 

    // MARK: – Init builds both pipelines from Shaders.metal file
    init(device: MTLDevice) {
        // 1️⃣ load the .metal source file from the SPM bundle
        guard let url = Bundle.module.url(forResource: "Shaders", withExtension: "metal"),
            let source = try? String(contentsOf: url) else {
            fatalError("Couldn't find Shaders.metal in Bundle.module")
        }

        // 2️⃣ compile it on the fly
        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: source, options: nil)
        } catch {
            fatalError("Metal compile error: \(error)")
        }

        // 3️⃣ build pipelines that are defined in teh .metal file
        let descBorder = MTLRenderPipelineDescriptor()
        descBorder.vertexFunction   = library.makeFunction(name: "vertex_main")
        /// Border glow to make the small_panel glow
        descBorder.fragmentFunction = library.makeFunction(name: "fragment_borderGlow")
        descBorder.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineBorder = try! device.makeRenderPipelineState(descriptor: descBorder)

        let descFull = MTLRenderPipelineDescriptor()
        descFull.vertexFunction   = library.makeFunction(name: "vertex_main")
        /// Full glow to make the small_panel pulse glow
        descFull.fragmentFunction = library.makeFunction(name: "fragment_fullGlow")
        descFull.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineFull = try! device.makeRenderPipelineState(descriptor: descFull)

        super.init()
    }

    convenience override init() {
        fatalError("Use shared instance")
    }

    func updateShade(from nsColor: NSColor) {
        let rgb = nsColor.usingColorSpace(.deviceRGB) ?? NSColor.black
        shadeColor = SIMD3<Float>(
            Float(rgb.redComponent),
            Float(rgb.greenComponent),
            Float(rgb.blueComponent)
        )
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

        /// Choosing the right pipeline
        switch currentEffect {
        case .none:
            /// We return because we dont want to draw anything if nothing is going on
            enc.endEncoding()
            buf.present(drawable)
            buf.commit()
            return;
        case .borderGlow:
            print("Using border glow Shader")
            enc.setRenderPipelineState(pipelineBorder)
        case .fullGlow:
            print("Using full glow Shader")
            enc.setRenderPipelineState(pipelineFull)
        }


        // -------- uniforms ----------
        var t = time
        enc.setFragmentBytes(&t, length: MemoryLayout<Float>.size, index: 0)

        var pulseInfo = SIMD4(shadeColor, pulseStrength)
        enc.setFragmentBytes(&pulseInfo, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
        // -----------------------------

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

struct MetalBackgroundView: NSViewRepresentable {

    @Binding var shade: NSColor
    @Binding var pulse: Bool

    func makeCoordinator() -> MetalCoordinator {
        MetalCoordinator.shared
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.pipelineBorder.device
        view.delegate = context.coordinator
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.updateShade(from: shade)

        if pulse {
            context.coordinator.useBorder = true
            context.coordinator.time = 0
            pulse = false
        }
    }
}
