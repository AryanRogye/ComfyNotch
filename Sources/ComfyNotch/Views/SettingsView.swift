import SwiftUI
import Combine


struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Int? = 0
    @State private var showTabBar: Bool = true
    
    let expandedSidebarWidth: CGFloat = 180
    // <<< How much space does the button *actually* need visually? >>>
    // Includes its internal padding & the VStack padding. Approx 40-55.
    let collapsedVisibleWidth: CGFloat = 55 // Keep this definition for the spacer

    // <<< Calculate the offset needed to show JUST the button >>>
    // Button starts visually around x=6 within container due to VStack padding.
    // If we want it to appear at x=5 on screen: offset = 5 - 6 = -1
    // Let's use a slightly larger offset for safety/visuals, e.g., -10
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                
                tabBar(isExpanded: $showTabBar) {
                    /// we have 3 right now
                    customTabOption(icon: "gearshape", title: "Settings", isSelected: selectedTab == 0) { selectedTab = 0 }
                    customTabOption(icon: "brain.head.profile", title: "AI Settings", isSelected: selectedTab == 1) { selectedTab = 1 }
                    customTabOption(icon: "keyboard", title: "Shorcut", isSelected: selectedTab == 2) { selectedTab = 2 }
                    Spacer()
                }
                .frame(width: expandedSidebarWidth)
                .offset(x: showTabBar ? 0 : collapsedOffsetValue)
                .animation(.easeInOut(duration: 0.25), value: showTabBar)
                .zIndex(1)
                // .offset(x: showTabBar ? 180 : 0)
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
        ZStack {
            VisualEffectView(
                material: .sidebar,
                blendingMode: .behindWindow
            )
            .frame(width: isExpanded ? 180 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            VStack(alignment: .leading, spacing: 1) {
                Button(action: {
                    showTabBar.toggle()
                } ) {
                    Image(systemName: "chevron.compact.down")
                }
                .padding(.vertical, 10)
                if isExpanded {
                    content()
                } else {
                    Spacer()
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 6)
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
    
    @ViewBuilder
    private func customTabOption(
        icon: String,
        title: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        /// Button for the actual "Tab"
        Button(action: action) {
            HStack {
                /// The Icons Image
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
                /// Title
                Text(title)
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
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

/// For Blur
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var emphasized: Bool = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = emphasized
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = emphasized
    }
}
