//
//  NotchGeneralTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/16/25.
//

import SwiftUI

struct NotchGeneralTab: View {
    
    @EnvironmentObject private var settings : SettingsModel
    
    @State private var openSettingsChanged          : Bool = false
    @State private var closedSettingsChanged    : Bool = false
    
    
    @State private var closedNotchValues
    : ClosedNotchValues = ClosedNotchValues()
    @State private var openSettingsDimensionValues
    : OpenNotchContentDimensionsValues = OpenNotchContentDimensionsValues()
    
    var body: some View {
        ComfyScrollView {
            openNotchContentDimensionSettings
            closedNotchSettings
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
                
                Button(action: {
                    settings.saveClosedNotchValues(values: closedNotchValues)
                    closedSettingsChanged = false
                }) {
                    Text("Save")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 1)
                        .background {
                            closedSettingsChanged
                            ? Color.red.opacity(0.2)
                            : Color.green.opacity(0.1)
                        }
                        .foregroundColor(
                            closedSettingsChanged
                            ? Color.red
                            : Color.green
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .contentShape(Rectangle())
                .buttonStyle(PlainButtonStyle())
                .controlSize(.small)
                .disabled(!closedSettingsChanged)
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
            
            Button(action: {
                settings.saveOpenNotchContentDimensions(values: openSettingsDimensionValues)
                openSettingsChanged = false
                
            }) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        openSettingsChanged
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.1)
                    }
                    .foregroundColor(
                        openSettingsChanged
                        ? Color.red
                        : Color.green
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!openSettingsChanged)
        }
    }
}
