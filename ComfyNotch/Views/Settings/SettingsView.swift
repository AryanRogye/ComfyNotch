import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Tab = .quickAccess
    
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    
    init() {}
    
    enum Tab: String, CaseIterable, Identifiable, Equatable {
        case quickAccess = "Quick Access"
        case general = "General"
        //        case shortcuts = "Shortcuts"
        case updates = "Updates"
        
        var id: String { rawValue }
        var label: String { rawValue }
        // MARK: - Icons
        var icon: String {
            switch self {
            case .quickAccess: return "square.and.arrow.up"
            case .general: return "gearshape"
                //            case .shortcuts: return "keyboard"
            case .updates: return "arrow.clockwise"
            }
        }
        
        // MARK: - Destination Views
        @ViewBuilder
        func destination(settings: SettingsModel) -> some View {
            switch self {
            case .quickAccess: QuickAccessSettingsView(settings: settings)
            case .general: GeneralSettingsView(settings: settings)
                //            case .shortcuts: ShortcutView(settings: settings)
            case .updates: UpdatesSettingsView(settings: settings)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(Tab.allCases, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Settings")
        } detail: {
            selectedTab.destination(settings: settings)
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial)
        }
        .transaction { $0.animation = nil }
        .frame(minWidth: 600, idealWidth: 750, maxWidth: 900, minHeight: 500)
        // MARK: - Window Management
        .onAppear {
            settings.isSettingsWindowOpen = true
            
            /// Make Sure That the Window is Above
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
}
