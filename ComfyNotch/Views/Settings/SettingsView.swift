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
        case general = "General"
        case notch = "Notch"
        case widgetSettings = "Widget Settings"
        case animations = "Animations"
        case display = "Display"
        case license = "License"
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
            case .license: return "doc.text"
            case .updates: return "arrow.triangle.2.circlepath"
            case .widgetSettings: return "square.grid.2x2"
            }
        }
        
        var color: AnyShapeStyle {
            switch self {
            case .widgetSettings:
                return AnyShapeStyle(Color(nsColor: .systemPink))
            case .general:
                return AnyShapeStyle(Color(nsColor: .systemGray))
            case .notch:
                return AnyShapeStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.62, green: 0.16, blue: 0.49),
                            Color(red: 0.86, green: 0.25, blue: 0.21),
                            Color(red: 1.00, green: 0.60, blue: 0.18)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            case .animations:
                return AnyShapeStyle(Color(nsColor: .systemBlue))
            case .display:
                return AnyShapeStyle(Color(nsColor: .systemGreen.withAlphaComponent(0.7)))
            case .license:
                return AnyShapeStyle(Color(nsColor: .systemPink))
            case .updates:
                return AnyShapeStyle(Color(nsColor: .systemBlue.withAlphaComponent(0.8)))
            }
        }
        
        var width: CGFloat {
            switch self {
            case .widgetSettings:
                return 20
            case .general:
                return 16
            case .notch:
                return 25
            case .animations:
                return 14
            case .display:
                return 10
            case .license:
                return 12
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
                return 24
            case .animations:
                return 14
            case .display:
                return 6
            case .license:
                return 12
            case .updates:
                return 15
            }
        }
        
        // MARK: - Destination Views
        @ViewBuilder
        func destination(settings: SettingsModel) -> some View {
            switch self {
            case .widgetSettings: WidgetSettings()
                
            case .notch:        NotchNotchTab()
            case .general:      NotchGeneralTab()
            case .animations:   NotchAnimationTab()
            case .display :     NotchDisplayTab()
            case .license :     NotchLicenseTab()
            case .updates:      NotchUpdatesTab()
            }
        }
    }
    
    // MARK: - body
    var body: some View {
        ZStack {
            settingsView
        }
        .onAppear {
            /// Make Sure That the Window is Above runs after 0.2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onDisappear {
            settings.refreshUI()
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
                
                
                sidebar
                
                
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
        .frame(minWidth: 770, idealWidth: 770, maxWidth: 770, minHeight: 600, maxHeight: 600)
        .onChange(of: localTabSelection) { _, newValue in
            settings.selectedTab = newValue
        }
        .onReceive(settings.$selectedTab) { newValue in
            if localTabSelection != newValue {
                localTabSelection = newValue
            }
        }
    }
    
    private var sidebar: some View {
        /// Sidebar for Settings to click
        /// TODO: REDO
        List(selection: $localTabSelection) {
            // Section for general tabs
            ForEach(SettingsView.Tab.allCases.filter {
                $0 != .updates && $0 != .license
            }, id: \.self) { tab in
                tabItem(tab)
                    .tag(tab)
            }
            
            // Section for "updates"
            Section("ComfyNotch") {
                ForEach(SettingsView.Tab.allCases.filter {
                    $0 == .updates || $0 == .license
                }, id: \.self) { tab in
                    tabItem(tab)
                        .tag(tab)
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    // MARK: - Helpers
    private func tabItem(_ tab: SettingsView.Tab) -> some View {
        HStack(spacing: 0) {
            image(for: tab)
            
            Text(tab.label)
                .font(.system(
                    size: 11,
                    weight: .regular,
                    design: .default
                ))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundColor(.primary)
                .padding(.leading, 6)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle()) // makes the whole row clickable
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.clear)
                .animation(.easeInOut(duration: 0.2), value: settings.selectedTab)
        )
    }
    
    
    // MARK: - Image For Tab and Size of Icon
    private func image(for tab: SettingsView.Tab) -> some View {
        return Group {
            if tab.rawValue == "Notch" {
                Image("comfypillowDesign")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: tab.width, height: tab.height)
            } else {
                Image(systemName: tab.icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
                    .frame(width: tab.width, height: tab.height)
            }
        }
        .frame(width: 22, height: 22)
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
        view.layer?.masksToBounds = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
