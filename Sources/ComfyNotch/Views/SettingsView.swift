import SwiftUI
import Combine


struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Int? = 0
    @State private var showTabBar: Bool = true

    var body: some View {
        VStack {
            /// Title of the screen will go here
            /// Toggle will also show up here
            HStack(alignment: .top) {
                Button(action: {
                    withAnimation {
                        showTabBar.toggle()
                    }
                } ) {
                    Image(systemName: "chevron.compact.down")
                }
                Spacer()
            }
            .padding(.leading, 5)
            
            HStack {
                /// Tab Bar
                tabBar(isExpanded: $showTabBar) {
                    /// we have 3 right now
                    customTabOption(action: {selectedTab = 0}, title: "Settings", isSelected: selectedTab == 0)
                    customTabOption(action: { selectedTab = 1 }, title: "AI Settings", isSelected: selectedTab == 1)
                    customTabOption(action: {selectedTab = 2} , title: "Shorcut", isSelected: selectedTab == 2)
                    Spacer()
                }
                /// The Actual View
                Group {
                    switch selectedTab {
                    case 0: MainSettingsView(settings: settings)
                    case 1: AISettingsView(settings: settings)
                    case 2: ShortcutView(settings: settings)
                    default: Text("Nothing Selected")
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: 700, maxHeight: 600)
        .onDisappear {
            settings.isSettingsWindowOpen = false
        }
    }
    
    @ViewBuilder
    private func tabBar<Content: View>(
        isExpanded: Binding<Bool>,
        @ViewBuilder content : () -> Content
    ) -> some View {
        let isExpanded = isExpanded.wrappedValue
        VStack(alignment: .leading, spacing: 1) {
            if isExpanded {
                content()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
    
    @ViewBuilder
    private func customTabOption(
        action: @escaping () -> Void,
        title: String,
        isSelected: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(6)
            .frame(maxWidth: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#Preview {
    SettingsView(settings: SettingsModel.shared)
}
