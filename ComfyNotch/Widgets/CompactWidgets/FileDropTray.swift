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
        Button(action: {
            animationState.isShowingFileTray.toggle()
        }) {
            ZStack {
                Text("Drop Files Here")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: 200, maxHeight: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 20)) // 👈 this is the REAL fix
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            dash: [6, 4]
                        )
                    )
                    .foregroundColor(animationState.isDroppingFiles ? Color.blue.opacity(0.8) : Color.white)
                    .shadow(
                        color: animationState.fileTriggeredTray
                            ? Color.purple.opacity(0.5)
                            : animationState.isDroppingFiles
                              ? Color.blue.opacity(0.5)
                              : .clear,
                        radius: animationState.fileTriggeredTray ? 12 : 6
                    )
                    .animation(.easeInOut(duration: 0.4), value: animationState.fileTriggeredTray)
            )
        }
        .buttonStyle(.plain)
        .padding(.leading, 10)
    }
}
