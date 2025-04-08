import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab = 0

    var body: some View {
        HStack {
            TabView(selection: $selectedTab) {
                MainSettingsView(settings: settings)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(0)
                AISettingsView(settings: settings)
                    .tabItem {
                        Image(systemName: "brain")
                        Text("AI Settings")
                    }
                    .tag(1)
                ShortcutView(settings: settings)
                    .tabItem {
                        Image(systemName: "keyboard")
                        Text("Shortcuts")
                    }
                    .tag(2)
            }
        }.onDisappear {
            settings.isSettingsWindowOpen = false
        }
    }    
}