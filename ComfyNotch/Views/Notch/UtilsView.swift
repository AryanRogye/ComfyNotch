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

struct Utils_BluetoothView: View {
    @ObservedObject private var bluetoothManager: BluetoothManager = .shared
    var devicesWithUniqueNames: [CBPeripheral] {
        var uniqueNames = Set<String>()
        var result: [CBPeripheral] = []
        
        for device in bluetoothManager.userBluetoothConnections {
            guard let name = device.name else { continue } // Skip unnamed devices
            
            // If we haven't seen this name before, add it to our results
            if !uniqueNames.contains(name) {
                uniqueNames.insert(name)
                result.append(device)
            }
        }
        
        return result
    }
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(devicesWithUniqueNames, id: \.self) { device in
                        HStack {
                            Text(device.name ?? "Unknown Device")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                            Spacer()
                            Button(action: { bluetoothManager.disconnect(device) }) {
                                Image(systemName: "bolt.slash.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 24)
                            }
                            .buttonStyle(.plain)
                            Button(action: { bluetoothManager.connect(device) }) {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 24)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 2)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.trailing, 8)
                }
                
            }
        }
        .onAppear {
            bluetoothManager.start()
        }
        .onDisappear {
            bluetoothManager.stopScanning()
        }
        .padding(.top, 2)
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
    }
}

struct Utils_ClipboardView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var currentIndex: Int = 0
    @State private var editorText: String = ""

    var body: some View {
        HStack(spacing: 2) {
            // Prev button
            Button(action: { move(-1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentIndex > 0 ? .blue : .gray)
            }
            .disabled(currentIndex == 0)

            // Editable, selectable text area
            TextEditor(text: $editorText)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
                .frame(maxWidth: .infinity) 
                .onAppear { editorText = currentItem }
                .onChange(of: currentItem) { _, new in editorText = new }

            // Next button
            Button(action: { move(+1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(currentIndex < clipboardManager.clipboardHistory.count - 1 ? .blue : .gray)
            }
            .disabled(currentIndex >= clipboardManager.clipboardHistory.count - 1)
        }
        .padding(.top, 2)
        .onChange(of: clipboardManager.clipboardHistory) { _, new in
            // jump to newest when history updates
            currentIndex = new.count - 1
            editorText = currentItem
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
    }

    private var currentItem: String {
        guard !clipboardManager.clipboardHistory.isEmpty,
              currentIndex >= 0,
              currentIndex < clipboardManager.clipboardHistory.count
        else { return "" }
        return clipboardManager.clipboardHistory[currentIndex]
    }

    private func move(_ offset: Int) {
        let newIndex = currentIndex + offset
        currentIndex = min(max(newIndex, 0), clipboardManager.clipboardHistory.count - 1)
        editorText = currentItem
    }
}
