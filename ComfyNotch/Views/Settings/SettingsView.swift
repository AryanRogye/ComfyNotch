import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var localTabSelection: Tab = SettingsModel.shared.selectedTab
    
    init() {}
    
    // MARK: - Tabs
    enum Tab: String, CaseIterable, Identifiable, Equatable {
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
            }
        }
        
        // MARK: - Destination Views
        @ViewBuilder
        func destination(settings: SettingsModel) -> some View {
            switch self {
                
            case .notch:        QuickAccessSettingsView(settings: settings)
            case .general:      GeneralSettingsView(settings: settings)
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
            List(selection: $localTabSelection) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    HStack(spacing: 8) {
                        if tab.rawValue == "Notch" {
                            Image("comfypillowDesign")
                                .resizable()
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 14)
                                .padding(.leading, 4)
                        } else {
                            Image(systemName: tab.icon)
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                        }
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
                    .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
        } detail: {
            settings.selectedTab.destination(settings: settings)
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial)
                .navigationTitle(localTabSelection.label)
        }
        .transaction { $0.animation = nil }
        .frame(minWidth: 800, idealWidth: 800, maxWidth: 900, minHeight: 600, maxHeight: 600)
        .onChange(of: localTabSelection) { _, newValue in
            settings.selectedTab = newValue
        }
        .onReceive(settings.$selectedTab) { newValue in
            if localTabSelection != newValue {
                localTabSelection = newValue
            }
        }
    }
}
