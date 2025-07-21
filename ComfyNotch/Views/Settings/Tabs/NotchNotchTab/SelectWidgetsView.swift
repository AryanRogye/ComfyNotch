//
//  SelectWidgetsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct SelectWidgetsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack {
            pickWidgets
        }
    }
    
    
     //  NOTE: To select widgets, we use this logic:
     //  
     //  .onTapGesture {
     //     if settings.selectedWidgets.contains(widgetName) {
     //         settings.updateSelectedWidgets(with: widgetName, isSelected: false)
     //     } else {
     //         settings.updateSelectedWidgets(with: widgetName, isSelected: true)
     //     }
     //  }
     //  This allows us to toggle widgets on and off
    private var pickWidgets: some View {
        let columns = [
            GridItem(.adaptive(minimum: 150), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(WidgetType.allCases, id: \.self) { widget in
                WidgetChip(widget: widget)
            }
        }
        .padding()
    }
}

struct WidgetChip: View {
    @EnvironmentObject var settings: SettingsModel
    let widget: WidgetType
    @State private var isHovering = false
    
    var isSelected: Bool {
        settings.selectedWidgets.contains(widget.rawValue)
    }
    
    var body: some View {
        HStack {
            widget.image
                .font(.headline)
                .foregroundColor(.white)
            
            Text(widget.shortName)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            if isHovering {
                Button {
                    settings.selectedTab = .widgetSettings
                    WidgetSettingsManager.shared.scrollToWidgetSettings(for: widget)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .foregroundColor(.primary)
                        .frame(width: 12, height: 12)
                        .background(Circle().fill(Color.white.opacity(0.7)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(widget.color.opacity(isSelected ? 0.9 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.white.opacity(0.7) : .clear, lineWidth: 2)
                        .shadow(color: isSelected ? Color.white.opacity(0.2) : .clear, radius: 4)
                )
        )
        .onTapGesture {
            let selected = isSelected
            settings.updateSelectedWidgets(with: widget.rawValue, isSelected: !selected)
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
