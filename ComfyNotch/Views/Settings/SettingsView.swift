import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Tab = .general
    
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    
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
                
            case .notch: QuickAccessSettingsView(settings: settings)
            case .general: GeneralSettingsView(settings: settings)
            case .animations: AnimationSettings(settings: settings)
            case .display : DisplaySettingsView(settings: settings)
            case .updates: UpdatesSettingsView(settings: settings)
                
            }
        }
    }
    
    // MARK: - body
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text(tab.label)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle()) // makes the whole row clickable
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.clear)
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    )
                    .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
        } detail: {
            selectedTab.destination(settings: settings)
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial)
        }
        .transaction { $0.animation = nil }
        .frame(minWidth: 700, idealWidth: 750, maxWidth: 900, minHeight: 500)
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
