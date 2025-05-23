import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject var settings = SettingsModel.shared
    @State private var selectedTab: Tab = .general
    
    init() {}

    enum Tab: String, CaseIterable, Identifiable, Equatable {
        case general = "General"
        case widget = "Widget"
        case ai = "AI"
        case shortcuts = "Shortcuts"
        case filetray = "File Tray"

        var id: String { rawValue }
        var label: String { rawValue }
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .widget: return "rectangle.3.offgrid"
            case .ai: return "brain.head.profile"
            case .shortcuts: return "keyboard"
            case .filetray: return "folder"
            }
        }

        @ViewBuilder
        func destination(settings: SettingsModel) -> some View {
            switch self {
            case .general: GeneralSettingsView(settings: settings)
            case .widget: WidgetsSettingsView(settings: settings)
            case .ai: AISettingsView(settings: settings)
            case .shortcuts: ShortcutView(settings: settings)
            case .filetray: FileTraySettingsView(settings: settings)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
        } detail: {
            selectedTab.destination(settings: settings)
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 700, minHeight: 500)
        .elevateToFloatingWindow()
        .onAppear {
            settings.isSettingsWindowOpen = true
        }
        .onDisappear {
            /// TODO: MAKE BETTER HERE
            settings.isSettingsWindowOpen = false
            SettingsModel.shared.refreshUI()
        }
    }
}


#Preview {
    SettingsView()
}
