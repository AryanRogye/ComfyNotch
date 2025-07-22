//
//  CurrentWidgetsDisplayView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct CurrentWidgetsDisplayView: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack {
            notchShapeOpen
            
            Divider()
                .padding(.top, 8)
            
            dragWidgetsHere
                .padding([.bottom])
        }
    }
    
    // MARK: - Drag Widgets Here
    
    
    @State private var detailsClicked: Bool = false
    
    /// place to drag the widgets
    private var dragWidgetsHere: some View {
        VStack {
            HStack(alignment: .center) {
                Text("Drag Widgets Here")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding([.horizontal])
            .padding(.top, 8)
            
            Divider()
                .padding(.vertical, 8)
            
            GeometryReader { geo in
                let count = max(settings.selectedWidgets.count, 1)
                let spacing: CGFloat = 1 * CGFloat(count - 1) // match your .padding(.horizontal, 1)
                let itemWidth = (geo.size.width - spacing) / CGFloat(count)
                
                HStack(spacing: 1) {
                    ForEach(settings.selectedWidgets, id: \.self) { widget in
                        draggingItem(for: widget)
                            .frame(width: itemWidth)
                            .padding(.horizontal, 3)
                    }
                }
            }
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 8)
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75, blendDuration: 0.3), value: settings.selectedWidgets)
            .padding(.horizontal)
            
        }
    }
    
    @State private var draggingItem: String? = nil
    @State private var isDragging: Bool = false
    
    /// this is the item that we drag
    private func draggingItem(for widget: String) -> some View {
        Text(widget)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    if draggingItem == widget && isDragging {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor.opacity(0.2))
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 2)
                            .blur(radius: 1)
                    }
                    
                    /// get color from widgetRegistry
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(widget.widgetType?.color ?? Color.clear)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .scaleEffect((draggingItem == widget && isDragging) ? 1.06 : 1.0)
            .animation(.smooth(duration: 0.3, extraBounce: 0.2), value: draggingItem == widget && isDragging)
            .onDrag {
                self.draggingItem = widget
                self.isDragging = true
                return NSItemProvider(object: NSString(string: widget))
            }
            .onDrop(of: [.plainText], delegate: DropViewDelegate(
                item: widget, settings: settings, draggingItem: $draggingItem, isDragging: $isDragging
            ))
    }
    
    // MARK: - Notch Shape
    private var notchShapeOpen: some View {
        ZStack {
            Image("ScreenBackgroundNotch")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            /// Notch Shape
            VStack(spacing: 0) {
                HStack {
                    /// TODO: ADD Fake Top Notch View
                }
                .frame(maxWidth: .infinity, maxHeight: 38)
                //                .border(Color.white, width: 1)
                
                notchContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 7)
            .frame(width: 400, height: 150)
            // MARK: - Actual Notch Shape
            .background(
                ComfyNotchShape(topRadius: 8, bottomRadius: 14)
                    .fill(Color.black)
            )
            /// this is cuz notch is 150 and image is 150, we push it up
            .padding(.top, -10)
        }
    }
    
    // MARK: - Notch Content
    private var notchContent: some View {
        VStack(alignment: .leading) {
            if settings.selectedWidgets.isEmpty {
                Text("No Widgets Selected")
            } else {
                HStack(spacing: 1) {
                    ForEach(settings.selectedWidgets, id: \.self) { widget in
                        draggableWidget(for: widget)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75, blendDuration: 0.3), value: settings.selectedWidgets)
            }
        }
    }
    
    // MARK: - Draggable Widget
    private func draggableWidget(for widget: String) -> some View {
        ZStack {
            getWidgetView(for: widget)
                .disabled(true)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)
        }
    }
    
    private func getWidgetView(for widget: String) -> some View {
        return VStack {
            Text(widget.widgetType?.rawValue ?? "Unknown Widget")
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(widget.widgetType?.color ?? Color.clear)
        }
        .padding(8)
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
