//
//  FileDropTray.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/23/25.
//

import SwiftUI

struct FileDropTray: View, Widget {
    var name: String = "FileDropTray"
    var alignment: WidgetAlignment? = .left

    var swiftUIView: AnyView {
        AnyView(self)
    }

    @Binding private var isDropping: Bool

    init() {
        let panelAnimationState = PanelAnimationState.shared
        let isDroppingFilesBinding = Binding<Bool>(
            get: { panelAnimationState.isDroppingFiles },
            set: { panelAnimationState.isDroppingFiles = $0 }
        )
        _isDropping = isDroppingFilesBinding
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isDropping ? Color.accentColor : Color.gray, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDropping ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .shadow(color: isDropping ? Color.accentColor.opacity(0.6) : .clear,
                        radius: isDropping ? 10 : 0, x: 0, y: 0)
                .scaleEffect(isDropping ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                           value: isDropping)
                .overlay(
                    Text("Drop Files Here")
                        .foregroundColor(.primary)
                        .scaleEffect(isDropping ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                                   value: isDropping)
                )
        }
        .padding()
    }
}
