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
            ComfyScrollView {
                musicPlayerSettings
                    .id(WidgetType.musicPlayer)
                
                cameraSettings
                    .id(WidgetType.camera)
                
            }
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
        }
    }
    
    private var cameraSettings: some View {
        ComfySettingsContainer {
            
        } header: {
            Text("Camera Widget Settings")
        }
    }
    
//    private var widgetSettings: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            if settings.selectedWidgets.contains(where: { $0.contains("Widget") }) {
//                ComfySection(title: "Widget Settings", isSub: true) {
//                    
//                    if settings.selectedWidgets.contains("AIChatWidget") {
//                        aiSettings
//                    }
//                    
//                    if settings.selectedWidgets.contains("MusicPlayerWidget") {
//                        musicPlayerSettings
//                    }
//                    
//                    if settings.selectedWidgets.contains("CameraWidget") {
//                        cameraSettingsSection
//                    }
//                    
//                    if settings.selectedWidgets.contains(where: {
//                        $0.contains("AIChatWidget") || $0.contains("MusicPlayerWidget") || $0.contains("CameraWidget")
//                    }) {
//                        comfyDivider
//                    }
//                    
//                }
//            }
//        }
//    }

}
