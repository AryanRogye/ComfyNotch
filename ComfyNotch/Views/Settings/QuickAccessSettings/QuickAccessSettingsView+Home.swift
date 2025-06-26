//
//  QuickAccessSettingsView+Home.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI
import AVKit

struct WidgetCardStyle: ViewModifier {
    
    let widgetName: String
    @ObservedObject var settings: SettingsModel = .shared
    
    var enabled : Bool {
        settings.selectedWidgets.contains(widgetName)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minHeight: 180)
            .frame(maxWidth: .infinity)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(enabled ? 1.02 : 1.0)
            .shadow(color: enabled ? .blue.opacity(0.6) : .black.opacity(0.2), radius: enabled ? 8 : 4)
            .animation(.spring(duration: 0.3), value: enabled)
            .onTapGesture {
                if settings.selectedWidgets.contains(widgetName) {
                    settings.updateSelectedWidgets(with: widgetName, isSelected: false)
                } else {
                    settings.updateSelectedWidgets(with: widgetName, isSelected: true)
                }
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

struct QuickAccessSettingsView_Home: View {
    
    @ObservedObject var settings: SettingsModel = .shared
    
    let widgetPreviews: [(widgetName: String,title: String, view: AnyView)] = [
        ("NotesWidget","Notes Widget", AnyView(NotesWidget())),
        ("MusicPlayerWidget","Music Player Widget", AnyView(MusicPlayerWidget())),
        ("EventWidget","Event Widget", AnyView(EventWidget())),
        ("AIChatWidget","AI Chat Widget", AnyView(AIChatWidget())),
        ("TimeWidget","Time Widget", AnyView(TimeWidget())),
        ("CameraWidget","Camera Widget", AnyView(CameraWidget()))
    ]
    
    @State private var draggingItem: String?
    @State private var isDragging = false
    
    var body: some View {
        VStack {
            titleView
            /// Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.bottom, 8)
            
            /// Arrange Widgets
            arrangeWidgets
            comfyDivider
            
            widgetSettings
            
            /// Widget Selection
            widgetSelection
        }
    }
    
    // MARK: - Title
    private var titleView: some View {
        HStack {
            Text("Home Settings")
                .font(.largeTitle)
            Spacer()
        }
    }
    
    // MARK: - Arrange Widgets
    private var arrangeWidgets: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Preview: Drag & Drop to Rearrange")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if settings.selectedWidgets.isEmpty {
                Text("No Widgets Selected")
            } else {
                HStack(spacing: 1) {
                    ForEach(settings.selectedWidgets, id: \.self) { widget in
                        draggableWidgetRow(for: widget)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Widget Settings
    private var widgetSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            if settings.selectedWidgets.contains(where: { $0.contains("Widget") }) {
                HStack {
                    Text("Widget Settings")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            if settings.selectedWidgets.contains("AIChatWidget") {
                settingsCard(title: "AI Settings") {
                    aiSettings
                }
            }
            
            settingsCard(title: "Music Player Settings") {
                if settings.selectedWidgets.contains("MusicPlayerWidget") {
                    musicPlayerSettings
                }
                // We Always Show a choose controller
                musicControllerPicker
            }
            
            if settings.selectedWidgets.contains("CameraWidget") {
                settingsCard(title: "Camera Settings") {
                    cameraSettingsSection
                }
            }
            
            if settings.selectedWidgets.contains(where: {
                $0.contains("AIChatWidget") || $0.contains("MusicPlayerWidget") || $0.contains("CameraWidget")
            }) {
                comfyDivider
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Widget Selection
    private var widgetSelection: some View {
        /// Widget Selection
        VStack(alignment: .leading ,spacing: 12) {
            HStack {
                Text("Widget Selection")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                if !settings.selectedWidgets.isEmpty {
                    Text("\(settings.selectedWidgets.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            /// Widget Selection
            
            // Other Widget Previews in a Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 20)], spacing: 24) {
                ForEach(widgetPreviews, id: \.title) { widget in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(widget.title)
                            .font(.headline)
                            .padding(.leading, 5)
                        if widget.title != "Event Widget" && widget.title != "Camera Widget" {
                            widget.view
                                .disabled(true)
                                .padding(5)
                                .modifier(WidgetCardStyle(widgetName: widget.widgetName))
                        } else {
                            Text("Preview Not Available For Widget")
                                .padding(5)
                                .modifier(WidgetCardStyle(widgetName: widget.widgetName))
                        }
                    }
                }
            }
            .padding(.horizontal)
            /// End of Widget Selection
        }
        .padding(.bottom, 80)
    }
    
    // MARK: - Helpers
    
    private func draggableWidgetRow(for widget: String) -> some View {
        ZStack {
            getWidgetView(for: widget)
                .disabled(true)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 180, maxHeight: 200)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .onDrag {
            self.draggingItem = widget
            self.isDragging = true
            return NSItemProvider(object: NSString(string: widget))
        }
        .onDrop(of: [.plainText], delegate: DropViewDelegate(
            item: widget, settings: settings, draggingItem: $draggingItem, isDragging: $isDragging
        ))
    }
    
    @ViewBuilder
    func getWidgetView(for widget: String) -> some View {
        switch widget {
        case "MusicPlayerWidget": MusicPlayerWidget()
        case "EventWidget": Text("Event Widget")
        case "AIChatWidget": AIChatWidget()
        case "TimeWidget": TimeWidget()
        case "NotesWidget": NotesWidget()
        case "CameraWidget": Text("Camera Widget")
        default: EmptyView()
        }
    }
    
    private var comfyDivider: some View {
        VStack {
            Spacer().frame(height: 20)
            /// Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 8)
            Spacer().frame(height: 20)
        }
    }
    
    // MARK: - Settings Helpers
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            content()
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var cameraSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            .onChange(of: settings.cameraQualitySelection) {
                settings.saveSettings()
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
                    in: 5...120,
                    step: 1
                )
                .transition(.opacity)
                .onChange(of: settings.cameraOverlayTimer) {
                    settings.saveSettings()
                }
            }
        }
    }
    
    private var musicPlayerSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $settings.showMusicProvider) {
                Text("Show Music Provider")
            }
            .toggleStyle(.switch)
            .onChange(of: settings.showMusicProvider) {
                settings.saveSettings()
            }
        }
    }
    
    private var musicControllerPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Music Controller", selection: $settings.musicController) {
                ForEach(MusicController.allCases, id: \.self) { controller in
                    Text(controller.displayName)
                        .tag(controller)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: settings.musicController) {
                settings.saveSettings()
            }
            Text("⚠️ Warning – Media Remote is a third-party Swift Package feature. Performance may vary, and optimizations may be limited.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            if settings.musicController == .mediaRemote {
                Picker("Music Provider", selection: $settings.overridenMusicProvider) {
                    ForEach(MusicProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName)
                            .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settings.overridenMusicProvider) {
                    settings.saveSettings()
                }
                .padding(.top, 2)
            }
        }
    }
    
    
    private var aiSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .onChange(of: settings.aiApiKey) {
                    settings.saveSettings()
                }
            
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
}
