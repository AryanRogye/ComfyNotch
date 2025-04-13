import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Int? = 0

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Settings", systemImage: "gear")
                    .tag(0)
                Label("AI Settings", systemImage: "brain")
                    .tag(1)
                Label("Shortcuts", systemImage: "keyboard")
                    .tag(2)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
        } detail: {
            Group {
                switch selectedTab {
                case 0: MainSettingsView(settings: settings)
                case 1: AISettingsView(settings: settings)
                case 2: ShortcutView(settings: settings)
                default: EmptyView()
                }
            }
        }
        .onDisappear {
            settings.isSettingsWindowOpen = false
        }
    }    
}


#Preview {
    SettingsView(settings: SettingsModel.shared)
}
