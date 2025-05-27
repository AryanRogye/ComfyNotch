//
//  MessagesView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/27/25.
//

import SwiftUI

struct MessagesView: View {
    
    @StateObject var animationState = PanelAnimationState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 2 : 0.1),
            value: animationState.isExpanded
        )
    }
}
