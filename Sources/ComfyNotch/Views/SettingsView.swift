import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Int? = 0
    @State private var showTabBar: Bool = true

    let expandedSidebarWidth: CGFloat = 180
    // <<< How much space does the button *actually* need visually? >>>
    let collapsedVisibleWidth: CGFloat = 55 // Keep this definition for the spacer

    // <<< Calculate the offset needed to show JUST the button >>>
    let collapsedOffsetValue: CGFloat = -69

    var body: some View {
        VStack(spacing: 0) {
            /// Title of the screen will go here

            ZStack(alignment: .leading) {
                /// Main Content Area
                HStack(spacing: 0) {
                    /// Spacer to push the content to the right
                    /// This simulates the actual tabbar being there
                    Spacer()
                        .frame(width: showTabBar ? expandedSidebarWidth : collapsedVisibleWidth)
                        .animation(.easeInOut(duration: 0.25), value: showTabBar)
                    /// The Actual View
                    Group {
                        switch selectedTab {
                        case 0: MainSettingsView(settings: settings)
                        case 1: AISettingsView(settings: settings)
                        case 2: ShortcutView(settings: settings)
                        default: Text("Nothing Selected")
                        }
                    }
                    .padding(.leading, showTabBar ? 0 : (collapsedOffsetValue + 15))
                    .animation(.easeInOut(duration: 0.25), value: showTabBar)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomSidebar(isExpanded: $showTabBar) {
                    /// we have 3 right now
                    CustomTabItem(
                        icon: "gearshape",
                        title: "Settings",
                        isSelected: selectedTab == 0
                    ) { selectedTab = 0 }

                    CustomTabItem(
                        icon: "brain.head.profile",
                        title: "AI Settings",
                        isSelected: selectedTab == 1
                    ) { selectedTab = 1 }

                    CustomTabItem(
                        icon: "keyboard",
                        title: "Shorcut",
                        isSelected: selectedTab == 2
                    ) { selectedTab = 2 }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: 700, maxHeight: 600)
        .onDisappear {
            settings.isSettingsWindowOpen = false
            SettingsModel.shared.refreshUI()
        }
    }
}

#Preview {
    SettingsView(settings: SettingsModel.shared)
}
