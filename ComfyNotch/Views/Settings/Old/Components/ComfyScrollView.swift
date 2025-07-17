//
//  ComfyScrollView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//

import SwiftUI

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
