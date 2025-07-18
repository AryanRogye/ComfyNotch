//
//  ComfySettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/16/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    
    /// MARK: - For now use the SettingsView.tabs
    @State private var localTabSelection: SettingsView.Tab = SettingsModel.shared.selectedTab
    
    init() {}
    
    enum Tab: String, CaseIterable, Identifiable, Equatable {
        case widgetSettings = "WidgetSettings"
        case general = "General"
        case notch = "Notch"
        case animations = "Animations"
        case display = "Display"
        case updates = "Updates"
        
        var id: String { rawValue }
        var label: String { rawValue }
        // MARK: - Icons
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .notch: return "notch"
            case .animations: return "sparkles"
            case .display: return "eye"
            case .updates: return "arrow.clockwise"
            case .widgetSettings: return "square.grid.2x2"
            }
        }
        
        var color: Color {
            switch self {
            case .widgetSettings:
                return Color(red: 0.8, green: 0.4, blue: 0.6) // soft pink
            case .general:
                return Color(red: 0.45, green: 0.45, blue: 0.47) // sleek dark gray
            case .notch:
                //                return Color(red: 0.93, green: 0.84, blue: 0.68) // #EED7AD
                return .black
            case .animations:
                return Color(red: 0.2, green: 0.6, blue: 1.0) // electric blue
            case .display:
                return Color(red: 1.0, green: 0.6, blue: 0.0) // bright orange
            case .updates:
                return Color(red: 0.2, green: 0.78, blue: 0.35) // fresh green
            }
        }
        
        var width: CGFloat {
            switch self {
            case .widgetSettings:
                return 20
            case .general:
                return 16
            case .notch:
                return 21
            case .animations:
                return 16
            case .display:
                return 16
            case .updates:
                return 14
            }
        }
        var height: CGFloat {
            switch self {
            case .widgetSettings:
                return 20
            case .general:
                return 16
            case .notch:
                return 20
            case .animations:
                return 16
            case .display:
                return 12
            case .updates:
                return 15
            }
        }
        
        // MARK: - Destination Views
        @ViewBuilder
        func destination(settings: SettingsModel) -> some View {
            switch self {
                
                //                            case .notch:        QuickAccessSettingsView(settings: settings)
                //                            case .general:      GeneralSettingsView(settings: settings)
                //                            case .animations:   AnimationSettings(settings: settings)
                //                            case .display :     DisplaySettingsView(settings: settings)
                //                            case .updates:      UpdatesSettingsView(settings: settings)
                
            case .widgetSettings: WidgetSettings()
            case .notch:        NotchSettingsView()
            case .general:      ComfyGeneralView()
            case .animations:   AnimationSettings(settings: settings)
            case .display :     DisplaySettingsView(settings: settings)
            case .updates:      UpdatesSettingsView(settings: settings)
            }
        }
    }
    
    
    // MARK: - body
    var body: some View {
        ZStack {
            /// If macOS 15 or higher, show settings view directly
            if #available(macOS 15, *) {
                settingsView
            }
            /// If is < 15, show loading view first and then the settings view
            /// this will help spam in the beginning
            else {
                if settings.hasFirstWindowBeenOpenOnce {
                    settingsView
                } else {
                    loadingView
                }
            }
        }
        .onAppear {
            settings.isSettingsWindowOpen = true
            
            /// Make Sure That the Window is Above runs after 0.2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NSApp.activate(ignoringOtherApps: true)
                
                // Find window by title or identifier
                if let window = NSApp.windows.first(where: {
                    $0.title.contains("Settings") || $0.identifier?.rawValue == "SettingsView"
                }) {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
        }
        .onDisappear {
            settings.isSettingsWindowOpen = false
            settings.refreshUI()
            NSApp.activate(ignoringOtherApps: false)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(alignment: .center) {
            Image("Logo")
                .resizable()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.bottom, 30)
            Text("Initializing ComfyNotch")
            Spacer()
        }
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400, minHeight: 400, maxHeight: 400)
        .onAppear {
            /// On First Launch just close the window
            if !settings.hasFirstWindowBeenOpenOnce {
                settings.isSettingsWindowOpen = true
                settings.checkForUpdatesSilently()
                /// Close the SettingsPage On Launch if not debug
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    if let window = NSApp.windows.first(where: { $0.title == "SettingsView" }) {
                        settings.isSettingsWindowOpen = false
                        window.performClose(nil)
                        window.close()
                    }
                    settings.hasFirstWindowBeenOpenOnce = true
                }
                /// Clsoe the window once
            }
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                /// Sidebar for Settings to click
                /// TODO: REDO
                List(selection: $localTabSelection) {
                    ForEach(SettingsView.Tab.allCases, id: \.self) { tab in
                        if tab.rawValue != "WidgetSettings" {
                            tabItem(tab)
                        }
                    }
                }
                .navigationSplitViewStyle(.prominentDetail)
                
                VStack {
                    Spacer()
                    
                    Button("Exit ComfyNotch", role: .destructive) {
                        closeWindow()
                    }
                    .keyboardShortcut("q", modifiers: [.command])
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(.bottom, 20)
                }
            }
            .navigationSplitViewColumnWidth(min: 145, ideal: 145, max: 145)
            
        } detail: {
            ZStack {
                
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                // MARK: - Detail For Selected Tab
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        image(for: settings.selectedTab)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .frame(width: 24, height: 24)
                        
                        Text(settings.selectedTab.label)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // MARK: - Destination
                    settings.selectedTab.destination(settings: settings)
                        .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle(localTabSelection.label)
                        .environmentObject(settings)
                    
                    Spacer()
                }
            }
        }
        .transaction { $0.animation = nil }
        .frame(minWidth: 735, idealWidth: 735, maxWidth: 735, minHeight: 600, maxHeight: 600)
        .onChange(of: localTabSelection) { _, newValue in
            settings.selectedTab = newValue
        }
        .onReceive(settings.$selectedTab) { newValue in
            if localTabSelection != newValue {
                localTabSelection = newValue
            }
        }
    }
    
    // MARK: - Helpers
    private func tabItem(_ tab: SettingsView.Tab) -> some View {
        return HStack(spacing: 8) {
            image(for: tab)
            Text(tab.label)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // makes the whole row clickable
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.clear)
                .animation(.easeInOut(duration: 0.2), value: settings.selectedTab)
        )
    }
    
    private func image(for tab: SettingsView.Tab) -> some View {
        return Group {
            if tab.rawValue == "Notch" {
                Image("comfypillowDesign")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: tab.width, height: tab.height)
            } else {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
                    .frame(width: tab.width, height: tab.height)
            }
        }
        .frame(width: 25, height: 25)
        .background (
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tab.color)
                .transition(.opacity)
        )
    }
    
    func closeWindow() {
        NSApp.terminate(nil)
    }
}



#Preview {
    SettingsView()
}


struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.masksToBounds = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
