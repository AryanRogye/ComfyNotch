import SwiftUI
import CoreBluetooth

enum UtilsTab: String, CaseIterable {
    case clipboard = "Clipboard"
}

struct UtilsView: View {
    @ObservedObject var settings: SettingsModel = .shared
    @ObservedObject var notchStateManager: NotchStateManager = .shared
    @ObservedObject var clipboardManager = ClipboardManager.shared
    
    @State private var expanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if notchStateManager.isExpanded {
                HStack {
                    if expanded {
                        ForEach(UtilsTab.allCases, id: \.self) { tab in
                            /// If clipboard is enabled
                            if (settings.enableClipboardListener || tab != .clipboard) {
                                Button(action: {
                                    notchStateManager.utilsSelectedTab = tab
                                }) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(notchStateManager.utilsSelectedTab == tab ? .blue : .white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(notchStateManager.utilsSelectedTab == tab ? Color.gray.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                
                /// Divider
                ZStack(alignment: .center) {
                    Divider()
                    Text(expanded ? "Close" : "Open")
                        .font(.footnote)
                        .padding(.horizontal, 6)
                        .background(Color.black)
                        .foregroundColor(.gray)
                        .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                }
                .onTapGesture {
                    withAnimation(.interpolatingSpring(duration: 0.3)) {
                        expanded.toggle()
                    }
                }
                
                VStack {
                    switch notchStateManager.utilsSelectedTab {
                        case .clipboard: Utils_ClipboardView(clipboardManager: clipboardManager)
                                            .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
                    }
                /// For now just the clipboard
                }
                .padding(.horizontal, 5)
            }
        }
        .background(Color.clear)
        .animation(
            .easeInOut(duration: notchStateManager.isExpanded ? 0.3 : 0.1),
            value: notchStateManager.isExpanded
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.interpolatingSpring(duration: 0.3)) {
                    expanded = false
                }
            }
        }
        .onDisappear {
            expanded = true
        }
        .keyboardShortcut("1", modifiers: [.command]) // Clipboard
        .keyboardShortcut("2", modifiers: [.command]) // Bluetooth
    }
}
