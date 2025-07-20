//
//  ComfyScrollView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//

import SwiftUI
import AppKit


struct ComfyScrollView<Content: View>: View {
    ///  take in content of what needs to be shown
    
    @ViewBuilder var content: () -> Content

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    content()
                }
                .padding()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}



/// A *very* lightweight NSScrollView wrapper tuned for performance.
//struct ComfyScrollView<Content: View>: NSViewRepresentable {
//    @ViewBuilder var content: () -> Content
//    
//    func makeNSView(context: Context) -> NSScrollView {
//        let scrollView = NSScrollView()
//        scrollView.hasHorizontalScroller = false
//        scrollView.hasVerticalScroller   = true
//        scrollView.usesPredominantAxisScrolling = true
//        scrollView.autohidesScrollers    = true
//        scrollView.drawsBackground       = false
//        scrollView.scrollerStyle         = .overlay
//        
//        // SwiftUI content
//        let hosting = NSHostingView(rootView:
//                                        content().padding()
//            .padding(.vertical, 8)
//            .frame(maxWidth: .infinity, alignment: .leading)   // still important
//        )
//        hosting.translatesAutoresizingMaskIntoConstraints = false
//        hosting.layer?.drawsAsynchronously = true
//        
//        // flipped container so y‑origin is at top
//        let flipped = FlippedView()
//        flipped.translatesAutoresizingMaskIntoConstraints = false
//        flipped.addSubview(hosting)
//        
//        // pin hosting to all edges of flipped
//        NSLayoutConstraint.activate([
//            hosting.leadingAnchor .constraint(equalTo: flipped.leadingAnchor),
//            hosting.trailingAnchor.constraint(equalTo: flipped.trailingAnchor),
//            hosting.topAnchor     .constraint(equalTo: flipped.topAnchor),
//            hosting.bottomAnchor  .constraint(equalTo: flipped.bottomAnchor)
//        ])
//        scrollView.documentView = flipped
//
//        // stretch flipped to scroll‑view width  💥 THIS is the magic line
//        flipped.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true
//        
//        return scrollView
//    }
//    
//    func updateNSView(_ nsView: NSScrollView, context: Context) {
//        if let hosting = nsView.documentView?.subviews.first as? NSHostingView<Content> {
//            hosting.rootView = content()
//        }
//    }
//}
//
//private final class FlippedView: NSView {
//    override var isFlipped: Bool { true }
//    override init(frame: NSRect) {
//        super.init(frame: frame)
//        wantsLayer = true
//    }
//    required init?(coder: NSCoder) { nil }
//}
