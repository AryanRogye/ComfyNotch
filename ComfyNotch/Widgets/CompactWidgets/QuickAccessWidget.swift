//
//  FileDropTray.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/23/25.
//

import SwiftUI


enum QuickAccessType: String {
    case dynamic = "Dynamic"
    case simple  = "Simple"
}

struct QuickAccessWidget: View, Widget {
    // MARK: - Widget Protocol
    var name: String = "QuickAccessWidget"
    var alignment: WidgetAlignment? = .left
    var swiftUIView: AnyView { AnyView(self) }
    
    @ObservedObject private var settings = SettingsModel.shared
    
    var body: some View {
        if settings.quickAccessWidgetSimpleDynamic == .dynamic {
            QuickAccessWidgetDynamic()
        } else {
            QuickAccessWidgetSimple()
        }
    }
}

struct QuickAccessWidgetDynamic: View, Widget {
    // MARK: - Widget Protocol
    var name: String = "QuickAccessWidget"
    var alignment: WidgetAlignment? = .left
    var swiftUIView: AnyView { AnyView(self) }
    
    private var height: CGFloat = 22
    
    
    // MARK: - Dependencies
    @ObservedObject private var notchStateManager = NotchStateManager.shared
    @ObservedObject private var musicModel        = MusicPlayerWidgetModel.shared
    @ObservedObject private var settings          = SettingsModel.shared
    
    
    // MARK: - Dynamic Segments
    private var segments: [(state: NotchViewState, icon: String, tooltip: String)] {
        var list: [(NotchViewState, String, String)] = [
            (.home,      "house",                   "Home"),
            (.file_tray, "tray.full",               "Files")
        ]
        if settings.enableMessagesNotifications {
            list.insert((.messages, "message",      "Messages"), at: 1)
        }
        if settings.enableUtilsOption {
            list.append((.utils,    "wrench.and.screwdriver", "Utilities"))
        }
        return list
    }
    
    // MARK: - View
    var body: some View {
        HStack {
            ForEach(segments, id: \.state) { seg in
                Button(action: {
                    notchStateManager.currentPanelState = seg.state
                }) {
                    Image(systemName: seg.icon)
                        .foregroundStyle(
                            notchStateManager.currentPanelState == seg.state
                            ? Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
                            : .white
                        )
                        .help(seg.tooltip)
                        .tag(seg.state)
                }
                .buttonStyle(.plain)
                .controlSize(.small)
            }
        }
        .frame(height: height)              // ← tighten up the height
        .padding(.leading, settings.quickAccessWidgetDistanceFromLeft)
        .padding(.top, settings.quickAccessWidgetDistanceFromTop)
    }
}


struct QuickAccessWidgetSimple: View, Widget {
    var name: String = "QuickAccessWidget"
    var alignment: WidgetAlignment? = .left
    
    /// Precomputed values
    /// WARNING: DO NOT CHANGE THIS VALUE
    /// This will move the notch to the right for some reason
    /// 8 - MOVES ALOT
    /// 7 - Moves a bit
    /// 6 - Cant rlly see unless you are looking closely
    private var widgetSpacing : CGFloat = 3
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject private var notchStateManager   : NotchStateManager = .shared
    @ObservedObject private var settings            : SettingsModel       = .shared
    @ObservedObject private var musicModel          : MusicPlayerWidgetModel = .shared
    
    private var width: CGFloat = 18
    private var height: CGFloat = 18
    
    var body: some View {
        HStack {
            homeButton
                .padding(.leading, widgetSpacing)
            
            if settings.enableMessagesNotifications {
                messagesButton
                    .padding(.leading, widgetSpacing)
            }
            if settings.enableUtilsOption {
                utilsButton
                    .padding(.leading, widgetSpacing)
            }
            
            fileTrayButton
                .padding(.leading, widgetSpacing)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.leading, settings.quickAccessWidgetDistanceFromLeft)
        .padding(.top, settings.quickAccessWidgetDistanceFromTop)
    }
    
    // MARK: - Home Button
    
    private var homeButton: some View {
        Button(action: {
            notchStateManager.currentPanelState = .home
        }) {
            Image(systemName: "house")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    notchStateManager.currentPanelState == .home
                    ? Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
                    : .white
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
            notchStateManager.currentPanelState = .messages
        }) {
            Image(systemName: "message")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    notchStateManager.currentPanelState == .messages
                    ? Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
                    : .white
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
            notchStateManager.currentPanelState = .utils
        } ) {
            Image(systemName: "wrench.and.screwdriver")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    notchStateManager.currentPanelState == .utils
                    ? Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
                    : .white
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
            notchStateManager.currentPanelState = .file_tray
        }) {
            Image(systemName: "tray.full")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    notchStateManager.currentPanelState == .file_tray
                    ? Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
                    : .white
                )
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}
