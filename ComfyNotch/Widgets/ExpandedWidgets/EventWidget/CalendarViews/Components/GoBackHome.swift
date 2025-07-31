//
//  GoBackHome.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/30/25.
//

import SwiftUI

struct GoBackHome<Content: View>: View {

    @EnvironmentObject var viewModel: EventWidgetViewModel
    let content: (() -> Content)?
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top) {
            
            if let content = content {
                content()
            } else {
                Spacer()
            }
            
            Button(action: {
                viewModel.dayViewState = .home
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
        }
    }
}
