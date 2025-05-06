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
    case notiification
}

struct PopInPresenter: View {
    
    var type: PopInPresenterType = .nowPlaying
    
    var body: some View {
        ZStack {
            switch type {
            case .nowPlaying:
                PopInPresenter_NowPlaying()
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
