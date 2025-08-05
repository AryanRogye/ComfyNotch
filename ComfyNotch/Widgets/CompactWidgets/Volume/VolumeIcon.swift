//
//  VolumeIcon.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/4/25.
//

import SwiftUI

public struct VolumeIcon: View, Widget {
    var name: String = "Volume Icon"
    var alignment: WidgetAlignment? = .right
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    public var body: some View {
        Image(systemName: "speaker.3")
            .padding(.top, 4)
            .padding(.trailing, 8)
    }
}
