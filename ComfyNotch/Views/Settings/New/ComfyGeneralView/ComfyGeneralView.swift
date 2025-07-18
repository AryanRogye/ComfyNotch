//
//  ComfyGeneralView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/16/25.
//

import SwiftUI

struct ComfyGeneralView: View {
    
    @State private var openSettingsChanged      : Bool = false
    @State private var closedSettingsChanged    : Bool = false
    
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
                didChange: $closedSettingsChanged
            )
        } header: {
            Text("Closed")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            Button(action: {}) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        closedSettingsChanged
                        ? Color.accentColor.opacity(0.2)
                        : Color.accentColor.opacity(0.1)
                    }
                    .foregroundColor(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!closedSettingsChanged)
        }
    }
    
    // MARK: - Open Notch Settings
    private var openNotchContentDimensionSettings: some View {
        ComfySettingsContainer {
            OpenNotchContentDimensionsView(
                didChange: $openSettingsChanged
            )
        } header: {
            Text("Open Notch Content Dimensions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
            
            Button(action: {}) {
                Text("Save")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        openSettingsChanged
                        ? Color.accentColor.opacity(0.2)
                        : Color.accentColor.opacity(0.1)
                    }
                    .foregroundColor(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            .controlSize(.small)
            .disabled(!openSettingsChanged)
        }
    }
}
