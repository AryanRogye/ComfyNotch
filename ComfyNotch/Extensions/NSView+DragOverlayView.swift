//
//  NSView+DragOverlayView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/23/25.
//

import AppKit

class DragOverlayView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("📂 Drag entered panel area!")

        // Open the panel when a file is dragged near
        DispatchQueue.main.async {
            ScrollHandler.shared.openFull()
            PanelAnimationState.shared.isExpanded = true
        }

        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("📂 Drag exited panel area!")
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
}
