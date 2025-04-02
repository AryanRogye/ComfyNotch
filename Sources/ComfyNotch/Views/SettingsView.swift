import SwiftUI
import Combine

class SettingsModel: ObservableObject {
    static let shared = SettingsModel() // Singleton for global access

    @Published var open_state_y_offset: CGFloat = 35
    @Published var isSettingsOpen: Bool = false
    @Published var flipCamera : Bool = false


    @Published var mappedWidgets: [String: Widget] = [
        "MusicPlayerWidget": MusicPlayerWidget(),
        "TimeWidget": TimeWidget(),
        "NotesWidget": NotesWidget(),
        "CameraWidget": CameraWidget(),
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

    private let maxWidgetCount = 3  // Limit to 3 widgets

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("ComfyNotch Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Customize your widgets and their arrangement")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                // Available Widgets Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Available Widgets")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    ForEach(Array(settings.mappedWidgets.keys.sorted()), id: \.self) { widgetName in
                        HStack {
                            Image(systemName: getIconName(for: widgetName))
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                            
                            Text(formatWidgetName(widgetName))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { settings.selectedWidgets.contains(widgetName) },
                                set: { isSelected in
                                    if isSelected {
                                        if settings.selectedWidgets.count < maxWidgetCount {
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
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Camera Settings")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    Toggle("Flip Camera", isOn: $settings.flipCamera)
                        .padding(.vertical, 8)
                }
                
                // Arrange Widgets Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Arrange Widgets")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    if settings.selectedWidgets.isEmpty {
                        Text("No widgets selected")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(settings.selectedWidgets, id: \.self) { widgetName in
                            HStack {
                                Image(systemName: getIconName(for: widgetName))
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                                
                                Text(formatWidgetName(widgetName))
                                
                                Spacer()
                                
                                Image(systemName: "line.3.horizontal")
                                    .padding(.trailing, 8)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(draggingItem == widgetName ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)))
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
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                
                Spacer()
                
                Button(action: closeWindow) {
                    Text("Exit ComfyNotch")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(width: 400, height: 600)
    }
    
    func formatWidgetName(_ name: String) -> String {
        var displayName = name
        if displayName.hasSuffix("Widget") {
            displayName = String(displayName.dropLast(6))
        }
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
        switch widgetName {
        case "MusicPlayerWidget":
            return "music.note"
        case "TimeWidget":
            return "clock"
        case "NotesWidget":
            return "note.text"
        case "CameraWidget":
            return "camera"
        default:
            return "square"
        }
    }
    
    func closeWindow() {
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
}