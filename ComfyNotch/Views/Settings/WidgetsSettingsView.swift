//
//  WidgetsSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI
import AVKit

struct WidgetsSettingsView: View {
    
    let widgetRegistry: WidgetRegistry = WidgetRegistry.shared
    @ObservedObject var settings: SettingsModel
    
    @State private var draggingItem: String?
    @State private var isDragging = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                saveSettingsButton
                    .padding([.top, .horizontal])
            }
            ComfyScrollView {
                headerView
                
                Divider()
                    .padding(.vertical, 8)
                
                arrangeWidgetsSection
                
                Divider()
                    .padding(.vertical, 8)
                
                availableWidgetsSection
                
                Divider()
                    .padding(.vertical, 8)
                
                aiSettings
                
                Divider()
                    .padding(.vertical, 8)
                
                cameraSettingsSection
                
                Divider()
                    .padding(.vertical, 8)
                
                musicPlayerSettings
                    .padding(.bottom, 32)
            }
        }
    }
    
    private var cameraSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Camera Settings")
                    .font(.headline)
                Spacer()
            }

            Toggle("Flip Camera", isOn: $settings.isCameraFlipped)
                .onChange(of: settings.isCameraFlipped) { settings.saveSettings() }
                .padding(.vertical, 8)
                .toggleStyle(.switch)
            
            /// Camera Quality
            Picker("Camera Quality", selection: $settings.cameraQualitySelection) {
                Text("4K (3840×2160)").tag(AVCaptureSession.Preset.hd4K3840x2160)
                Text("Full HD (1920×1080)").tag(AVCaptureSession.Preset.hd1920x1080)
                Text("HD (1280×720)").tag(AVCaptureSession.Preset.hd1280x720)
                Text("High (Auto)").tag(AVCaptureSession.Preset.high)
                Text("Medium (640×480)").tag(AVCaptureSession.Preset.medium)
                Text("Low (352×288)").tag(AVCaptureSession.Preset.low)
                Text("Photo (Still Only)").tag(AVCaptureSession.Preset.photo)
            }
            
            Toggle("Enable Camera Overlay", isOn: $settings.enableCameraOverlay)
                .onChange(of: settings.enableCameraOverlay) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        settings.saveSettings()
                    }
                }
                .padding(.vertical, 8)
                .toggleStyle(.switch)
            
            if settings.enableCameraOverlay {
                ComfyLabeledStepper(
                    "Overlay Timer",
                    value: $settings.cameraOverlayTimer,
                    in: 5...120
                )
                .transition(.opacity)
            }
        }
    }
    
    private var musicPlayerSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Music Player Widget Settings")
                    .font(.headline)
                Spacer()
            }
            
            // TODO: Add music player settings here
            Toggle(isOn: $settings.showMusicProvider) {
                Text("Show Music Provider")
            }
            .toggleStyle(.switch)
            .onChange(of: settings.showMusicProvider) {
                settings.saveSettings()
            }
            
        }
    }
    
    private var aiSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Settings")
                    .font(.headline)
                Spacer()
            }

            TextField("AI API Key", text: $settings.aiApiKey)
                .textFieldStyle(PlainTextFieldStyle()) // ✅ Removes system styling
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.1))
                )
                .padding()
                .focusable(true)
            
            HStack {
                Spacer()
                Button( action: addFromClipboard ) {
                    Text("Add From Clipboard")
                }
                .padding(.horizontal)
            }
        }
    }
    
    func addFromClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            settings.aiApiKey = clipboardString
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
    
    private var saveSettingsButton: some View {
        Button("Save Settings") {
            settings.saveSettings()
        }
        .keyboardShortcut("s", modifiers: [.command])
        .buttonStyle(.bordered)
        .controlSize(.regular)
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
