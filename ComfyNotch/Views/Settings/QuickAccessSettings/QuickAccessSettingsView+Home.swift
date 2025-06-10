//
//  QuickAccessSettingsView+Home.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct WidgetCardStyle: ViewModifier {
    
    let widgetName: String
    @StateObject var settings: SettingsModel = .shared
    
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
    
    @StateObject var settings: SettingsModel = .shared

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
            Text("Home Settings")
                .font(.largeTitle)
            
            // Arrange Widgets
            VStack(spacing: 16) {
                HStack {
                    Text("Arrange Widgets")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    if !settings.selectedWidgets.isEmpty {
                        Text("\(settings.selectedWidgets.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
         
            /// Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 8)

            VStack(alignment: .leading ,spacing: 12) {
                HStack {
                    Text("Widget Selection")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
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
    }
    
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
}
