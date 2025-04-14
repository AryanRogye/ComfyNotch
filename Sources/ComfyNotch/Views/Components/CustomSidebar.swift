//
//  SwiftUIView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/14/25.
//

import SwiftUI

struct CustomSidebar<Content: View>: View {
    let isExpanded: Binding <Bool>
    let content : () -> Content
    
    init(
        isExpanded : Binding<Bool>,
        @ViewBuilder content : @escaping () -> Content
    ) {
        self.isExpanded = isExpanded
        self.content = content
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(
                material: .sidebar,
                blendingMode: .behindWindow
            )
            .frame(width: isExpanded.wrappedValue ? 180 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            
            VStack(alignment: .leading, spacing: 1) {
                /// Button to toggle the sidebar
                Button(action: {
                    isExpanded.wrappedValue.toggle()
                } ) {
                    Image(systemName: "chevron.compact.down")
                }
                .padding(.vertical, 10)
                
                /// Actual Content
                if isExpanded.wrappedValue {
                    content()
                } else {
                    Spacer()
                }
                
            }
            .padding(.top, 10)
            .padding(.horizontal, 6)
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: isExpanded.wrappedValue)
    }
}

#Preview {
    let isExpanded: Binding<Bool> = .constant(true)
    CustomSidebar(isExpanded: isExpanded) {
        Text("")
    }
}
