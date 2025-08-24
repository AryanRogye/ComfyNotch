//
//  NotchGeneralTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/16/25.
//

import SwiftUI

struct NotchGeneralTab: View {
    
    @EnvironmentObject private var settings : SettingsModel
    
    @State private var openSettingsChanged      : Bool = false
    @State private var closedSettingsChanged    : Bool = false
    @State private var proximitySettingsChanged : Bool = false
    
    
    @State private var proximityValues             : ProximitySettingsValues = ProximitySettingsValues()
    @State private var closedNotchValues           : ClosedNotchValues = ClosedNotchValues()
    @State private var openSettingsDimensionValues : OpenNotchContentDimensionsValues = OpenNotchContentDimensionsValues()
    
    var body: some View {
        ComfyScrollView {
            proximitySettings
            openNotchContentDimensionSettings
            closedNotchSettings
        }
    }
    
    // MARK: - Proximity Settings
    private var proximitySettings: some View {
        ComfySettingsContainer {
            ProximitySettings(
                values: $proximityValues,
                didChange: $proximitySettingsChanged
            )
        } header: {
            HStack {
                Text("Proximity Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                ComfyButton(title: "Save", $proximitySettingsChanged) {
                    // TODO: Impliment
                    settings.saveProximitySettingsValues(values: proximityValues)
                    proximitySettingsChanged = false
                }
            }
        }
    }
    
    // MARK: - Closed Notch Settings
    private var closedNotchSettings: some View {
        ComfySettingsContainer {
            ClosedNotchGeneralSettings(
                values: $closedNotchValues,
                didChange: $closedSettingsChanged
            )
        } header: {
            HStack {
                Text("Closed")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                
                ComfyButton(title: "Save", $closedSettingsChanged) {
                    settings.saveClosedNotchValues(values: closedNotchValues)
                    closedSettingsChanged = false
                }
            }
        }
    }
    
    // MARK: - Open Notch Settings
    private var openNotchContentDimensionSettings: some View {
        ComfySettingsContainer {
            OpenNotchContentDimensionsView(
                values: $openSettingsDimensionValues,
                didChange: $openSettingsChanged
            )
        } header: {
            Text("Open Notch Content Dimensions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            ComfyButton(title: "Save", $openSettingsChanged) {
                settings.saveOpenNotchContentDimensions(values: openSettingsDimensionValues)
                openSettingsChanged = false
            }
        }
    }
}
