//
//  SwiftUIView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/14/25.
//

import SwiftUI

struct CustomSidebar<Content: View>: View {

    @Binding var isExpanded: Bool
    let content: () -> Content
    let expandedSidebarWidth: CGFloat
    let collapsedOffsetValue: CGFloat

    init(
        isExpanded: Binding<Bool>,
        expandedSidebarWidth: CGFloat = 180,
        collapsedOffsetValue: CGFloat = -65,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isExpanded = isExpanded
        self.content = content
        self.expandedSidebarWidth = expandedSidebarWidth
        self.collapsedOffsetValue = collapsedOffsetValue
    }

    var body: some View {
        ZStack {
            VisualEffectView(
                material: .sidebar,
                blendingMode: .behindWindow
            )
            .frame(width: isExpanded ? 180 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 0))

            VStack(alignment: .leading, spacing: 1) {
                /// Button to toggle the sidebar
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Image(systemName: "chevron.compact.left")
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        .animation(.easeInOut(duration: 0.25), value: isExpanded)
                }
                .padding(.trailing, 20)
                .padding(.vertical, 10)

                /// Actual Content
                if isExpanded {
                    content()
                } else {
                    Spacer()
                }

            }
            .padding(.top, 10)
            .padding(.horizontal, 6)
        }
        .clipped()
        .frame(width: expandedSidebarWidth)
        .offset(x: isExpanded ? 0 : collapsedOffsetValue)
        .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .zIndex(1)

    }
}

#Preview {
    let isExpanded: Binding<Bool> = .constant(true)
    CustomSidebar(isExpanded: isExpanded) {
        Text("")
    }
}
