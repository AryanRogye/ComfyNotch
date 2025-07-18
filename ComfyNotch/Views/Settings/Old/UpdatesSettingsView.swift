//
//  UpdatesSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/24/25.
//

import SwiftUI

struct UpdatesSettingsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        ComfyScrollView {
            appImage
            
            appVersion
            
            appBuild
            
            releaseNotes
            
            Divider()
            
            checkForUpdates
            
            Spacer()
        }
    }
    
    // MARK: - App Icon
    private var appImage: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 64, height: 64)
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - App Version Number
    private var appVersion: some View {
        Text("Version \(Bundle.main.versionNumber)")
            .font(.body)
    }
    
    // MARK: - App Build Number
    private var appBuild: some View {
        Text("Build \(Bundle.main.buildNumber)")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    // MARK: - Release Notes
    private var releaseNotes: some View {
        Button("View Release Notes") {
            if let url = URL(string: "https://github.com/AryanRogye/ComfyNotch/releases/latest") {
                NSWorkspace.shared.open(url)
            }
        }
        .buttonStyle(.link)
        .font(.footnote)
    }
    
    // MARK: - Check for Updates
    private var checkForUpdates: some View {
        Button("Check for Updates") {
            settings.checkForUpdates()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .keyboardShortcut("u", modifiers: [.command])
    }
}
