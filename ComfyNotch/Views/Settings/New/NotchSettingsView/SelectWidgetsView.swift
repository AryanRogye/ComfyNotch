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
            HStack {
                VStack {
                    Text("Time Widget")
                }
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.2))
                }
                .onTapGesture {
                    if settings.selectedWidgets.contains("TimeWidget") {
                        settings.updateSelectedWidgets(with: "TimeWidget", isSelected: false)
                    } else {
                        settings.updateSelectedWidgets(with: "TimeWidget", isSelected: true)
                    }
                }
                
                VStack {
                    Text("Music Player Widget")
                }
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.2))
                }
                .onTapGesture {
                    if settings.selectedWidgets.contains("MusicPlayerWidget") {
                        settings.updateSelectedWidgets(with: "MusicPlayerWidget", isSelected: false)
                    } else {
                        settings.updateSelectedWidgets(with: "MusicPlayerWidget", isSelected: true)
                    }
                }
                
            }
        }
    }
}
