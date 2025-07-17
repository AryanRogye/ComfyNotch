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
            HStack(alignment: .top) {
                header()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 3)

            HStack(alignment: .top, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .quaternarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
