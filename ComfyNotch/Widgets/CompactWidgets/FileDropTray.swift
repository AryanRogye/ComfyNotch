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

    @ObservedObject private var panelAnimationState: PanelAnimationState = .shared

    var body: some View {
        ZStack {
            Text("Drop Files Here")
        }
        .frame(maxWidth: 400, maxHeight: .infinity)
        .border(panelAnimationState.isDroppingFiles ? Color.blue : Color.white, width: 1)
    }
}
