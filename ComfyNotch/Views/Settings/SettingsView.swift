import SwiftUI
import Combine

extension View {
    func elevateToFloatingWindow() -> some View {
        self.background(WindowAccessor { window in
            window?.level = .floating
            window?.makeKeyAndOrderFront(nil)
        })
    }
}

// This helper grabs the NSWindow from the view hierarchy
private struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.onResolve(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var selectedTab: Tab = .general

    enum Tab: String, CaseIterable, Identifiable, Equatable {
        case general = "General"
        case ai = "AI"
        case shortcuts = "Shortcuts"
        case filetray = "File Tray"

        var id: String { rawValue }
        var label: String { rawValue }
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .ai: return "brain.head.profile"
            case .shortcuts: return "keyboard"
            case .filetray: return "folder"
            }
        }

        @ViewBuilder
        func destination(settings: SettingsModel) -> some View {
            switch self {
            case .general: MainSettingsView(settings: settings)
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
            settings.isSettingsWindowOpen = false
            SettingsModel.shared.refreshUI()
        }
    }
}
