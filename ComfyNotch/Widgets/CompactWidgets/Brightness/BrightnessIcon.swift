//
//  BrightnessIcon.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/5/25.
//

import SwiftUI


public struct BrightnessIcon: View, Widget {
    var name: String = "Brightness Icon"
    var alignment: WidgetAlignment? = .right
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    public var body: some View {
        Image(systemName: "sun.max.fill")
            .padding(.top, 4)
            .padding(.trailing, 8)
    }
}
