//
//  ComfySettingsContainer.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ComfySettingsContainer<Content: View, Header: View>: View {
    let content: () -> Content
    let header: () -> Header?
    
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Header?
    ) {
        self.content = content
        self.header = header
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                header()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 12)
            .zIndex(1)
            
            GroupBox {
                content()
            }
        }
    }
}

extension ComfySettingsContainer where Header == EmptyView {
    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(content: content, header: { EmptyView() })
    }
}
