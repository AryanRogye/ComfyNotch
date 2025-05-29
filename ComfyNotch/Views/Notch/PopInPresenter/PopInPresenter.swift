//
//  PopInPresenter.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/6/25.
//

import SwiftUI

enum PopInPresenterType {
    case none
    case nowPlaying
    case messages
    case hud
    case notiification
}

struct PopInPresenter: View {
    
    @StateObject private var panelState = PanelAnimationState.shared
    
    var body: some View {
        ZStack {
            switch panelState.currentPopInPresentationState {
            case .nowPlaying:
                PopInPresenter_NowPlaying()
            case .hud:
                PopInPresenter_HUD()
            case .messages:
                PopInPresenter_Messages()
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
