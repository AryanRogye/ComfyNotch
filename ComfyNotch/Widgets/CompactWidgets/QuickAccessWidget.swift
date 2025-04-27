//
//  FileDropTray.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/23/25.
//

import SwiftUI

struct QuickAccessWidget: View, Widget {
    var name: String = "QuickAccessWidget"
    var alignment: WidgetAlignment? = .left

    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject private var animationState: PanelAnimationState = .shared

    var body: some View {
        HStack {
            Button(action: {
                animationState.currentPanelState = .home
            }) {
                    Image(systemName: "house")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(
                            animationState.currentPanelState == .home ? .blue : .white
                        )
                        .padding(5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            .buttonStyle(.plain)

            Button(action: {
                animationState.currentPanelState = .utils
            } ) {
                Image(systemName: "wrench.and.screwdriver")
                   .resizable()
                   .frame(width: 20, height: 20)
                   .foregroundColor(
                        animationState.currentPanelState == .utils ?.blue : .white
                    )
                   .padding(5)
                   .background(Color.black.opacity(0.5))
                   .cornerRadius(10)
                  .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            .buttonStyle(.plain)
            .padding(.leading, 10)

            Button(action: {
                animationState.currentPanelState = .file_tray
            }) {
                    Image(systemName: "tray.full")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(
                            animationState.currentPanelState == .file_tray ? .blue : .white
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
