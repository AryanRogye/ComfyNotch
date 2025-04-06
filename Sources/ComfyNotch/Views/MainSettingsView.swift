import SwiftUI

struct MainSettingsView : View {
    @ObservedObject var settings: SettingsModel
    let widgetRegistry: WidgetRegistry = WidgetRegistry.shared
    @State private var draggingItem: String?
    @State private var isDragging = false
    @Environment(\.colorScheme) var colorScheme

    private let maxWidgetCount = 3  // Limit to 3 widgets

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                availableWidgetsSection
                cameraSettingsSection
                arrangeWidgetsSection
                Spacer()
                exitButton
            }
            .padding()
        }
        .frame(width: 400, height: 600)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("ComfyNotch Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Customize your widgets and their arrangement")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 12)
    }
    
    private var availableWidgetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Widgets")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            ForEach(Array(widgetRegistry.widgets.keys.sorted()), id: \.self) { widgetName in
                widgetToggleRow(for: widgetName)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func widgetToggleRow(for widgetName: String) -> some View {
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
                    settings.updateSelectedWidgets(with: widgetName, isSelected: isSelected)
                }
            ))
            .labelsHidden()
            // .disabled(!settings.selectedWidgets.contains(widgetName) && settings.selectedWidgets.count >= maxWidgetCount)
        }
        .padding(.vertical, 8)
    }
    
    private var cameraSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Camera Settings")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            Toggle("Flip Camera", isOn: $settings.isCameraFlipped)
                .onChange(of: settings.isCameraFlipped) { _ in settings.saveSettings() }
                .padding(.vertical, 8)
        }
    }
    
    private var arrangeWidgetsSection: some View {
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
                    draggableWidgetRow(for: widgetName)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func draggableWidgetRow(for widgetName: String) -> some View {
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
    
    private var exitButton: some View {
        Button(action: closeWindow) {
            Text("Exit ComfyNotch")
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
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