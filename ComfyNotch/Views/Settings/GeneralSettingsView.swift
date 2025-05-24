import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedSaveHUD: Bool = false

    private let maxWidgetCount = 3  // Limit to 3 widgets

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                notchSettingsSection
                cameraSettingsSection
                dividerSettingsSection
                Spacer()
                saveSettingsButton
                exitButton
            }
            .padding()
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
            } else {
                MediaKeyInterceptor.shared.stop()
                VolumeManager.shared.stop()
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
        }
    }


    // MARK: - Buttons
    private var saveSettingsButton: some View {
        Button(action: {
            settings.enableNotchHUD = selectedSaveHUD
            settings.saveSettings()
        } ) {
            Text("Save Settings")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private var exitButton: some View {
        Button(action: closeWindow) {
            Text("Exit ComfyNotch")
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Functions
    
    func closeWindow() {
        NSApp.terminate(nil)
    }
}
