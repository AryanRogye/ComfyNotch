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
    
    
    /*
     * NOTE: To select widgets, we use this logic:
     *
     *
     .onTapGesture {
     if settings.selectedWidgets.contains(widgetName) {
     settings.updateSelectedWidgets(with: widgetName, isSelected: false)
     } else {
     settings.updateSelectedWidgets(with: widgetName, isSelected: true)
     }
     }
     * This allows us to toggle widgets on and off
     *
     *
     */
    private var pickWidgets: some View {
        VStack {
            
            let columns = [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ]
            
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(WidgetType.allCases, id: \.self) { widget in
                    HStack {
                        HStack {
                            Text(widget.shortName)
                                .padding(20)
                            Spacer()
                        }
                        .onTapGesture {
                            if settings.selectedWidgets.contains(widget.rawValue) {
                                settings.updateSelectedWidgets(with: widget.rawValue, isSelected: false)
                            } else {
                                settings.updateSelectedWidgets(with: widget.rawValue, isSelected: true)
                            }
                        }
                        
                        showSettingsButton(for: widget)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(widget.color.opacity(0.9))
                    }
                    
                }
            }
        }
    }
    
    private func showSettingsButton(for widget: WidgetType) -> some View {
        Button(action: {
            settings.selectedTab = .widgetSettings
            WidgetSettingsManager.shared.scrollToWidgetSettings(for: widget)
        }) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.white)
                .padding(8)
                .background {
                    ZStack {
                        Circle().fill(widget.color)
                        
//                        Color.black.opacity(0.2)
//                            .clipShape(Circle())
                    }
                }
        }
        .buttonStyle(.plain)
        .padding(.trailing)
    }
}
