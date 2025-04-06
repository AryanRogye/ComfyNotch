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

struct DropViewDelegate: DropDelegate {
    var item: String
    var settings: SettingsModel
    @Binding var draggingItem: String?
    @Binding var isDragging: Bool

    func performDrop(info: DropInfo) -> Bool {
        guard let draggingItem = draggingItem else { return false }
        
        if let fromIndex = settings.selectedWidgets.firstIndex(of: draggingItem),
           let toIndex = settings.selectedWidgets.firstIndex(of: item),
           fromIndex != toIndex {
            
            withAnimation {
                let movedItem = settings.selectedWidgets.remove(at: fromIndex)
                settings.selectedWidgets.insert(movedItem, at: toIndex)
            }

            settings.saveSettings()  // Save the updated order to disk
            NotificationCenter.default.post(name: NSNotification.Name("ReloadWidgets"), object: nil)

            self.draggingItem = nil
            self.isDragging = false
            return true
        }
        return false
    }
}
