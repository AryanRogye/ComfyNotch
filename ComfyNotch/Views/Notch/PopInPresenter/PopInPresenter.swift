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
    case notiification
}

struct PopInPresenter: View {
    
    @ObservedObject private var notchStateManager = NotchStateManager.shared
    
    var body: some View {
        ZStack {
            switch notchStateManager.currentPopInPresentationState {
            case .nowPlaying:
                PopInPresenter_NowPlaying()
            case .messages:
                PopInPresenter_Messages()
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
