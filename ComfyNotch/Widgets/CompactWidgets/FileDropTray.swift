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

    @ObservedObject private var animationState: PanelAnimationState = .shared

    var body: some View {
        HStack {
            Button(action: {
                animationState.isShowingFileTray = false
            }) {
                    Image(systemName: "house")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(
                            animationState.isShowingFileTray ? .white : .blue
                        )
                        .padding(5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                }
                .buttonStyle(.plain)
            Button(action: {
                animationState.isShowingFileTray = true
            }) {
                    Image(systemName: "tray.full")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(
                            animationState.isShowingFileTray ? .blue : .white
                        )
                        .padding(5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                }
                .buttonStyle(.plain)
                .padding(.leading, 10)
        }
    }
}
