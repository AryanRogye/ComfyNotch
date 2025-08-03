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
    
    @State private var eventWidgetValues = EventWidgetSettingsValues()
    @State private var eventValuesDidChange = false
    
    @State private var musicWidgetValues = MusicPlayerSettingsValues()
    @State private var musicValuesDidChange = false
    
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
                    
                    eventSettings
                        .padding(.vertical)
                        .id(WidgetType.event)
                }
                .frame(maxWidth: .infinity)
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
            MusicPlayerSettings(
                didChange: $musicValuesDidChange,
                values: $musicWidgetValues
            )
        } header: {
            
            Text("Music Player Widget Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
            
            ComfyButton(title: "Save", $musicValuesDidChange) {
                settings.saveMusicWidgetValues(values: musicWidgetValues)
                musicValuesDidChange = false
            }
            .accessibilityIdentifier("MusicPlayerSettingsSaveButton")
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
    
    private var eventSettings: some View {
        ComfySettingsContainer {
            EventWidgetSettings(
                didChange: $eventValuesDidChange,
                values: $eventWidgetValues
            )
        } header: {
            HStack {
                Text("Event Widget Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                
                ComfyButton(title: "Save", $eventValuesDidChange) {
                    settings.saveEventsValues(values: eventWidgetValues)
                    eventValuesDidChange = false
                }
            }
        }
    }
}
