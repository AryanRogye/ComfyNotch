//
//  InformationCircle.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/2/25.
//

import SwiftUI

struct InformationCirclee: View {
    
    private var clickedText: String
    @State private var isClicked: Bool = false
    
    init(clickedText: String) {
        self.clickedText = clickedText
    }
    
    var body: some View {
        ZStack {
            Circle()
                .scaleEffect(0.1)
                .opacity(0.2)
                .overlay (
                    Text("i")
                )
                .onTapGesture {
                    self.isClicked = true
                }
            if isClicked {
                Text(clickedText)
                    .onTapGesture {
                        self.isClicked = false
                    }
            }
        }
    }
}
