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
                    .frame(maxWidth: 400, maxHeight: .infinity)
            }
            .border(animationState.isDroppingFiles ? Color.blue : Color.white, width: 1)
        }
        .buttonStyle(.plain)
    }
}
