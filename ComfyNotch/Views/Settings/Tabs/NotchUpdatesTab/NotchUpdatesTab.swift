//
//  NotchUpdatesTab.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/19/25.
//

import SwiftUI

struct NotchUpdatesTab: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        ComfyScrollView {
            ComfySettingsContainer {
                headerImageInfo
            }
            
            ComfySettingsContainer {
                appInfo
            }
            
            ComfySettingsContainer {
                appMisc
            }
            
            Spacer()
        }
    }
    
    private var appMisc: some View {
        VStack {
            HStack {
                releaseNotes
                Spacer()
            }
            .padding([.horizontal, .top])
            
            
            Divider().padding(.vertical, 8)
            
            HStack {
                checkForUpdates
                Spacer()
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    private var appInfo: some View {
        VStack {
            HStack {
                Text("Version:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                appVersion
            }
            .padding([.horizontal, .top])
            
            Divider().padding(.vertical, 8)
            
            HStack {
                Text("Build:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                appBuild
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    private var headerImageInfo: some View {
        HStack {
            VStack(alignment: .leading) {
                appImage
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text("ComfyNotch")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Button {
                        if let url = URL(string: "https://github.com/AryanRogye/ComfyNotch") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("View on GitHub", systemImage: "link")
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.leading)
                }
                
                Text("Turns your MacBook’s notch into a customizable HUD with widgets, music, brightness, volume controls, and more ⚡ Built for macOS 14+ with Swift.")
                    .minimumScaleFactor(0.5)
                    .lineLimit(3)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - App Icon
    private var appImage: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 64, height: 64)
            .cornerRadius(12)
    }
    
    // MARK: - App Version Number
    private var appVersion: some View {
        Text("\(Bundle.main.versionNumber)")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
    }
    
    // MARK: - App Build Number
    private var appBuild: some View {
        Text("\(Bundle.main.buildNumber)")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
    }
    
    // MARK: - Release Notes
    private var releaseNotes: some View {
        HStack {
            Text("Release Notes")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            Button("View") {
                if let url = URL(string: "https://github.com/AryanRogye/ComfyNotch/releases/latest") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.system(size: 13))
        }
    }
    
    // MARK: - Check for Updates
    private var checkForUpdates: some View {
        HStack {
            Text("Check for Updates")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            Button("Check") {
                settings.checkForUpdates()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .font(.system(size: 13, weight: .semibold))
            .keyboardShortcut("u", modifiers: [.command])
        }
        .padding(.vertical, 2)
    }
}
