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
    
    /// Precomputed values
    /// WARNING: DO NOT CHANGE THIS VALUE
    /// This will move the notch to the right for some reason
    /// 8 - MOVES ALOT
    /// 7 - Moves a bit
    /// 6 - Cant rlly see unless you are looking closely
    private var widgetSpacing : CGFloat = 5
    private var distanceFromEdge : CGFloat = 7
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject private var animationState: PanelAnimationState = .shared
    
    var body: some View {
        HStack {
            homeButton
                .padding(.leading, widgetSpacing)
            
            messagesButton
                .padding(.leading, widgetSpacing)
            
            utilsButton
                .padding(.leading, widgetSpacing)
            
            fileTrayButton
                .padding(.leading, widgetSpacing)
        }
        .padding(.leading, distanceFromEdge)
    }
    
    // MARK: - Home Button
    
    private var homeButton: some View {
        Button(action: {
            animationState.currentPanelState = .home
        }) {
            Image(systemName: "house")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: 21, height: 20)
                .foregroundColor(
                    animationState.currentPanelState == .home ? .blue : .white
                )
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Messages Button
    
    private var messagesButton: some View {
        Button(action: {
            animationState.currentPanelState = .messages
        }) {
            Image(systemName: "message")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(
                    animationState.currentPanelState == .messages ? .blue : .white
                )
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Utils Button
    
    private var utilsButton: some View {
        Button(action: {
            animationState.currentPanelState = .utils
        } ) {
            Image(systemName: "wrench.and.screwdriver")
                .symbolRenderingMode(.hierarchical)
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
    }
    
    // MARK: - File Tray Button
    
    private var fileTrayButton: some View {
        Button(action: {
            animationState.currentPanelState = .file_tray
        }) {
            Image(systemName: "tray.full")
                .symbolRenderingMode(.hierarchical)
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
    }
}
