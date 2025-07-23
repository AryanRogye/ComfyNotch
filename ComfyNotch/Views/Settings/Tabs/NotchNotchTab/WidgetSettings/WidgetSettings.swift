//
//  WidgetSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI


class WidgetSettingsManager: ObservableObject {
    static let shared = WidgetSettingsManager()
    
    @Published var targetWidgetToScrollTo: WidgetType?
    
    func scrollToWidgetSettings(for widget: WidgetType) {
        targetWidgetToScrollTo = widget
    }
}

struct WidgetSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    @ObservedObject private var widgetSettingsManager = WidgetSettingsManager.shared
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    
                    musicPlayerSettings
                        .padding(.vertical)
                        .id(WidgetType.musicPlayer)
                    
                    cameraSettings
                        .padding(.vertical)
                        .id(WidgetType.camera)
                }
                .padding()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onReceive(widgetSettingsManager.$targetWidgetToScrollTo) { target in
                if let target = target {
                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    widgetSettingsManager.targetWidgetToScrollTo = nil
                }
            }
        }
    }
    
    private var musicPlayerSettings: some View {
        ComfySettingsContainer {
            MusicPlayerSettings()
        } header: {
            Text("Music Player Widget Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
        }
    }
    
    private var cameraSettings: some View {
        ComfySettingsContainer {
            CameraSettings()
        } header: {
            Text("Camera Widget Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}
