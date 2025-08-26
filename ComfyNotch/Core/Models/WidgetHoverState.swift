//
//  WidgetHoverState.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/25/25.
//

import SwiftUI

final class WidgetHoverState: ObservableObject {
    static let shared = WidgetHoverState()
    
    @Published var isHovering: Bool = false
    @Published var isHoveringOverEvents: Bool = false
}
