import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedSaveHUD: Bool = false

    private let maxWidgetCount = 3  // Limit to 3 widgets

    var body: some View {
        VStack {
            HStack {
                Spacer()
                saveSettingsButton
                    .padding([.top, .horizontal])
            }
            ComfyScrollView {
                headerView
                
                notchSettingsSection
                
                cameraSettingsSection
                
                dividerSettingsSection
                
                Spacer()
                
                exitButton
            }
            .onAppear {
                selectedSaveHUD = settings.enableNotchHUD
            }
            .onChange(of: settings.enableNotchHUD) { _, newValue in
                if newValue {
                    /// Start The Media Key Interceptor
                    MediaKeyInterceptor.shared.start()
                    /// Start Volume Manager
                    VolumeManager.shared.start()
                    BrightnessWatcher.shared.start()
                } else {
                    MediaKeyInterceptor.shared.stop()
                    VolumeManager.shared.stop()
                    BrightnessWatcher.shared.stop()
                }
            }
        }
    }
    
    // MARK: - HEADER
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("ComfyNotch Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.top, 12)
    }
    
    // MARK: - Notch Section
    private var notchSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notch Settings")
                    .font(.headline)
                Spacer()
            }
            Divider()
            
            hudSettings
            Divider()
            scrollSpeed
        }
    }
    
    private var hudSettings: some View {
        HStack {
            /// One Side Volume Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("HUD Settings")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Toggle(isOn: $selectedSaveHUD) {
                    Text("")
                }
                .toggleStyle(.switch)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Not seeing the HUD?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button(action: MediaKeyInterceptor.shared.requestAccessibility) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield")
                            Text("Request Accessibility Permissions")
                                .underline()
                        }
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            Spacer()
            
            if let videoURL = Bundle.main.url(forResource: "enableNotchHUD_demo", withExtension: "mp4", subdirectory: "Assets") {
                LoopingVideoView(url: videoURL)
                    .frame(width: 350 ,height: 120)
                    .cornerRadius(10)
            }
        }
    }
    
    private var scrollSpeed: some View {
        HStack {
            /// One Side Notch Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Scroll Speed")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 10) {
                    Button(action: {
                        settings.nowPlayingScrollSpeed = max(1, settings.nowPlayingScrollSpeed - 1)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.borderless)
                    
                    Text("\(settings.nowPlayingScrollSpeed)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .frame(minWidth: 28, alignment: .center)
                    
                    Button(action: {
                        settings.nowPlayingScrollSpeed += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.borderless)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Adjust the scroll speed for the Now Playing widget.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("Default: 40")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button("Reset to Default") {
                        settings.nowPlayingScrollSpeed = 40
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            Spacer()
            /// Other Side Video Demo
            if let videoURL = Bundle.main.url(forResource: "nowPlayingScrollSpeed_demo", withExtension: "mp4", subdirectory: "Assets") {
                LoopingVideoView(url: videoURL)
                    .frame(width: 350 ,height: 120)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Camera Section
    private var cameraSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Camera Settings")
                    .font(.headline)
                Spacer()
            }

            Divider()

            Toggle("Flip Camera", isOn: $settings.isCameraFlipped)
                .onChange(of: settings.isCameraFlipped) { settings.saveSettings() }
                .padding(.vertical, 8)
                .toggleStyle(.switch)
        }
    }
    
    // MARK: - Divider Section
    
    private var dividerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Divider Settings")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            Toggle("Enable Divider", isOn: $settings.showDividerBetweenWidgets)
                .onChange(of: settings.showDividerBetweenWidgets) {
                    settings.saveSettings()
                }
                .padding(.vertical, 8)
                .toggleStyle(.switch)
        }
    }


    // MARK: - Buttons
    private var saveSettingsButton: some View {
        Button("Save Settings") {
            settings.enableNotchHUD = selectedSaveHUD
            settings.saveSettings()
        }
        .keyboardShortcut("s", modifiers: [.command])
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }
    
    private var exitButton: some View {
        Button("Exit ComfyNotch", role: .destructive) {
            closeWindow()
        }
        .keyboardShortcut("q", modifiers: [.command])
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    // MARK: - Helper Functions
    
    func closeWindow() {
        NSApp.terminate(nil)
    }
}
