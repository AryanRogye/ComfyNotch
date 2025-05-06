import SwiftUI
import CoreBluetooth

enum UtilsTab: String, CaseIterable {
    case clipboard = "Clipboard"
//    case wifi = "Wi-Fi"
    case bluetooth = "Bluetooth"
}

struct UtilsView: View {
    @StateObject var animationState: PanelAnimationState = .shared
    @StateObject var clipboardManager = ClipboardManager.shared
    @State private var selectedTab: UtilsTab = .clipboard

    var body: some View {
        VStack(spacing: 0) {
            if animationState.isExpanded {
                HStack {
                    ForEach(UtilsTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? .blue : .white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedTab == tab ? Color.gray.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.top, 1)
                Divider()
                VStack {
                    switch selectedTab {
                        case .clipboard: Utils_ClipboardView(clipboardManager: clipboardManager)
                                            .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
                        case .bluetooth: Utils_BluetoothView()
                        default: EmptyView()
                    }
                /// For now just the clipboard
                }
                .padding(.horizontal, 5)
            }
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
    }
}
