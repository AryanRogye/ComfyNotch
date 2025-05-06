import SwiftUI
import AppKit
import Combine
import MetalKit

struct MetalBlobView: NSViewRepresentable {
    func makeCoordinator() -> RendererCoordinator { RendererCoordinator() }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 120
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    class RendererCoordinator: NSObject, MTKViewDelegate {
        private var startTime = CACurrentMediaTime()
        private var pipelineState: MTLRenderPipelineState!
        private var commandQueue: MTLCommandQueue!
        private var vertexBuffer: MTLBuffer!

        override init() {
            super.init()
            let device = MTLCreateSystemDefaultDevice()!
            let library = device.makeDefaultLibrary()!

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexPassthrough")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "blobFragment")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            commandQueue = device.makeCommandQueue()

            let quadVertices: [Float] = [
                -1, -1,  0, 1,
                 1, -1,  1, 1,
                -1,  1,  0, 0,
                 1,  1,  1, 0,
            ]
            vertexBuffer = device.makeBuffer(bytes: quadVertices, length: MemoryLayout<Float>.size * quadVertices.count, options: [])
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

            var time = Float(CACurrentMediaTime() - startTime)
            encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
