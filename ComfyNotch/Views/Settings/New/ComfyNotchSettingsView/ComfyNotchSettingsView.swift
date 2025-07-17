//
//  ComfyNotchSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

/// Fully RE-DONE Settings View for ComfyNotch
/// NO AI COPY PASTE HERE

struct ComfyNotchSettingsView: View {
    
    @State private var openSettingsChanged      : Bool = false
    @State private var closedSettingsChanged    : Bool = false
    
    var body: some View {
        ComfyScrollView {
            openNotchSettings
            
            closedNotchSettings
        }
    }
    
    // MARK: - Closed Notch Settings
    private var closedNotchSettings: some View {
        ComfySettingsContainer {
            ComfyNotchSettingsView_ClosedNotchSettings(
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
    private var openNotchSettings: some View {
        ComfySettingsContainer {
            ComfyNotchSettingsView_OpenNotchSettings(
                didChange: $openSettingsChanged
            )
        } header: {
            Text("Open")
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
