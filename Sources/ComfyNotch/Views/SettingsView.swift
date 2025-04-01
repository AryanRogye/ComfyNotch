import SwiftUI
import Combine

class SettingsModel: ObservableObject {
    static let shared = SettingsModel() // Singleton for global access

    @Published var open_state_y_offset: CGFloat = 35


    @Published var mappedWidgets: [String: Widget] = [
        "MusicPlayerWidget": MusicPlayerWidget(),
        "TimeWidget": TimeWidget(),
        "NotesWidget": NotesWidget()
    ]
    
    @Published var selectedWidgets: [String] = ["MusicPlayerWidget", "TimeWidget", "NotesWidget"] // Default selected widgets

    private var cancellables = Set<AnyCancellable>()

    init() {
    $selectedWidgets
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main) // Give it some time before triggering the reload
            .sink { _ in
                NotificationCenter.default.post(name: NSNotification.Name("ReloadWidgets"), object: nil)
            }
            .store(in: &cancellables)
    }
}
struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @State private var draggingItem: String?
    @State private var isDragging = false
    @Environment(\.colorScheme) var colorScheme
    
    // Computed properties for dynamic colors
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray) : Color(.systemBrown)
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray) : Color(.systemGray)
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("ComfyNotch Settings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("Customize your widgets and their arrangement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Open State Y Offset")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.and.down")
                        .foregroundColor(.blue)
                }
                
                Slider(value: $settings.open_state_y_offset, in: 0...100, step: 1)
                    .onChange(of: settings.open_state_y_offset) { _ in
                        ScrollManager.shared.applyOffsetChange()
                    }
                    .accentColor(.blue)
                    .padding(.horizontal, 16)
            }
            .padding()
            
            // Available Widgets Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Widgets")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                ForEach(Array(settings.mappedWidgets.keys.sorted()), id: \.self) { widgetName in
                    HStack {
                        // Widget icon (placeholders)
                        Image(systemName: getIconName(for: widgetName))
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                        
                        // Widget name with friendlier display
                        Text(formatWidgetName(widgetName))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.selectedWidgets.contains(widgetName) },
                            set: { isSelected in
                                if isSelected {
                                    if !settings.selectedWidgets.contains(widgetName) {
                                        settings.selectedWidgets.append(widgetName)
                                    }
                                } else {
                                    settings.selectedWidgets.removeAll { $0 == widgetName }
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

            // Arrange Widgets Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Arrange Widgets")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                if settings.selectedWidgets.isEmpty {
                    HStack {
                        Spacer()
                        Text("No widgets selected")
                            .foregroundColor(.secondary)
                            .italic()
                        Spacer()
                    }
                    .padding()
                } else {
                    ForEach(settings.selectedWidgets, id: \.self) { widgetName in
                        HStack {
                            Image(systemName: getIconName(for: widgetName))
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                            
                            Text(formatWidgetName(widgetName))
                                .foregroundColor(textColor)
                            
                            Spacer()
                            
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(draggingItem == widgetName ? Color.blue.opacity(0.1) : cardBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(draggingItem == widgetName ? Color.blue : Color.clear, lineWidth: 1)
                        )
                        .onDrag {
                            self.draggingItem = widgetName
                            self.isDragging = true
                            return NSItemProvider(object: NSString(string: widgetName))
                        }
                        .onDrop(of: [.plainText], delegate: DropViewDelegate(item: widgetName, settings: settings, draggingItem: $draggingItem, isDragging: $isDragging))
                    }
                }
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer()
            
            // Exit Button
            Button(action: closeWindow) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Exit ComfyNotch")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 600)
        .background(backgroundColor)
    }
    
    // Helper functions for better UI
    func formatWidgetName(_ name: String) -> String {
        // Remove "Widget" suffix and add spaces between words
        var displayName = name
        if displayName.hasSuffix("Widget") {
            displayName = String(displayName.dropLast(6))
        }
        
        // Add spaces between camel case words
        var formattedName = ""
        for char in displayName {
            if char.isUppercase && !formattedName.isEmpty {
                formattedName += " "
            }
            formattedName += String(char)
        }
        
        return formattedName
    }
    
    func getIconName(for widgetName: String) -> String {
        // Return appropriate SF Symbol names based on widget type
        switch widgetName {
        case "MusicPlayerWidget":
            return "music.note"
        case "TimeWidget":
            return "clock"
        case "NotesWidget":
            return "note.text"
        default:
            return "square"
        }
    }

    func closeWindow() {
        NSApplication.shared.keyWindow?.close()
        NSApp.terminate(nil)
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
            self.draggingItem = nil
            self.isDragging = false
            return true
        }
        return false
    }

    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem else { return }
        
        if let fromIndex = settings.selectedWidgets.firstIndex(of: draggingItem),
           let toIndex = settings.selectedWidgets.firstIndex(of: item),
           fromIndex != toIndex {
            
            withAnimation {
                let movedItem = settings.selectedWidgets.remove(at: fromIndex)
                settings.selectedWidgets.insert(movedItem, at: toIndex)
            }
        }
    }

    func dropExited(info: DropInfo) {
        isDragging = false
    }
}