//
//  WidgetsSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI

struct WidgetsSettingsView: View {
    
    let widgetRegistry: WidgetRegistry = WidgetRegistry.shared
    @ObservedObject var settings: SettingsModel
    
    @State private var draggingItem: String?
    @State private var isDragging = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                
                Divider()
                    .padding(.vertical, 8)

                arrangeWidgetsSection
                
                Divider()
                    .padding(.vertical, 8)
                
                availableWidgetsSection
            }
            .padding()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Widgets Settings")
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
            
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(widgetRegistry.widgets.keys.sorted()), id: \.self) { widgetName in
                    widgetToggleRow(for: widgetName)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func widgetToggleRow(for widgetName: String) -> some View {
        VStack {
            HStack {
                Image(systemName: getIconName(for: widgetName))
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                
                Text(formatWidgetName(widgetName))
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                if settings.selectedWidgets.contains(widgetName) {
                    settings.updateSelectedWidgets(with: widgetName, isSelected: false)
                } else {
                    settings.updateSelectedWidgets(with: widgetName, isSelected: true)
                }
            }) {
                Text(settings.selectedWidgets.contains(widgetName) ? "Enabled" : "Disabled")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(settings.selectedWidgets.contains(widgetName) ? Color.green : Color.red)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

//            Toggle("", isOn: Binding(
//                get: { settings.selectedWidgets.contains(widgetName) },
//                set: { isSelected in
//                    settings.updateSelectedWidgets(with: widgetName, isSelected: isSelected)
//                }
//            ))
//            .labelsHidden()
        }
        .padding(.vertical, 8)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    draggingItem == widgetName ?
                        Color.blue.opacity(0.1) :
                        Color.gray.opacity(0.1)
                )
        )
        .onDrag {
            self.draggingItem = widgetName
            self.isDragging = true
            return NSItemProvider(object: NSString(string: widgetName))
        }
        .onDrop(of: [.plainText], delegate: DropViewDelegate(
                item: widgetName, settings: settings, draggingItem: $draggingItem, isDragging: $isDragging
            ))
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
        case "EventWidget":
            return "calendar"
        case "AIChatWidget":
            return "message"
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

            settings.saveSettings()  // Save the updated order to disk
            settings.removeAndAddBackCurrentWidgets()

            self.draggingItem = nil
            self.isDragging = false
            return true
        }
        return false
    }
}

