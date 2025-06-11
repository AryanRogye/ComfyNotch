import SwiftUI

struct GeneralSettingsView: View {
    
    @ObservedObject var settings: SettingsModel
    @StateObject    var displayManager: DisplayManager = .shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedSaveHUD: Bool = false
    
    @State private var notchWidthStep: CGFloat = 1.0
    @State private var startNotchWidth: CGFloat? = nil
    @State private var notchWidthChanged: Bool = false
    @State private var lastNotchWidth: CGFloat = 0.0
    @State private var resetPressed: Bool = false
    
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
                
                // displaySettingsSection
                
                notchSettingsSection
                
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
        .onAppear {
            if startNotchWidth == nil {
                startNotchWidth = settings.notchMaxWidth
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
    
    // MARK: - Display Section
    private var displaySettingsSection: some View {
        ComfySection(title: "Display Settings") {
            displaySection
        }
    }
    
    private var displaySection: some View {
        VStack {
            HStack {
                let columns = [
                    /// 2 displays Max
                    GridItem(.flexible(minimum: 100, maximum: 200)),
                    GridItem(.flexible(minimum: 100, maximum: 200)),
                ]
                Spacer()
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(displayManager.screenSnapshots.keys), id: \.self) { key in
                        if let image = displayManager.snapshot(for: key) {
                            let screen = NSScreen.screens.first(where: { $0.displayID == key })
                            VStack {
                                Text(displayManager.displayName(for: key))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 140)
                                    .cornerRadius(8)
                                    .padding(4)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Button(action: {
                                    displayManager.selectedScreen = screen
                                    displayManager.saveSettings()
                                }) {
                                    Text("Select")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(6)
                            .padding(.horizontal, 8)
                            .background(displayManager.selectedScreen ==  screen ? Color.primary.opacity(0.3) : Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            VStack(alignment: .center) {
                Text("Note that ComfyNotch will open the best on a window with a Notch")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                Text("A newly selected Display will need a relaunch to apply settings properly")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Notch Section
    private var notchSettingsSection: some View {
//        ComfySection(title: "Notch Settings") {
        VStack {
            ComfySection(title: "Dimensions", isSub: true) {
                notchSettings
            }
            ComfySection(title: "Display", isSub: true) {
                displaySection
            }
            ComfySection(title: "Animations", isSub: true) {
                animationSettings
            }
            ComfySection(title: "Notch Controls", isSub: true) {
                scrollSpeed
                hudSettings
            }
            ComfySection(title: "Divider Settings") {
                Toggle("Enable Divider", isOn: $settings.showDividerBetweenWidgets)
                    .onChange(of: settings.showDividerBetweenWidgets) {
                        settings.saveSettings()
                    }
                    .padding(.vertical, 8)
                    .toggleStyle(.switch)
            }
        }
    }
    
    private var animationSettings: some View {
        VStack {
            Picker("", selection: $settings.openingAnimation) {
                Text("Spring Animation").tag("spring")
                Text("iOS Animation").tag("iOS")
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(.accentColor)
            .onChange(of: settings.openingAnimation) {
                settings.saveSettings()
            }
            
            //            LoopingVideoView(url: Bundle.main.url(forResource: "notchAnimation_demo", withExtension: "mp4", subdirectory: "Assets")!)
            //                .frame(width: 350, height: 120)
            //                .cornerRadius(10)
        }
    }
    
    private var notchSettings: some View {
        HStack {
            VStack {
                Group {
                    ComfyLabeledStepper(
                        "Notch Width (Expanded)",
                        value: $settings.notchMaxWidth,
                        in: 700...1000,
                        step: notchWidthStep
                    )
                    /// This is to show a tooltip or a description
                    /// if the notch width is changed to something that the user
                    /// did not start with
                    .onChange(of: settings.notchMaxWidth) { _, newValue in
                        if newValue != self.startNotchWidth {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.notchWidthChanged = true
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.notchWidthChanged = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                /// Control For Step
                HStack {
                    Text("Step Size: \(Int(notchWidthStep))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Slider(value: $notchWidthStep, in: 1...10, step: 1) {
                        Text("Step Size")
                    }
                    .labelsHidden()
                    .onChange(of: notchWidthStep) { _, newValue in
                        settings.notchMaxWidth = max(500, min(1000, settings.notchMaxWidth))
                    }
                }
                .padding(.horizontal)
                
                /// Change The Distance From Left For Quick Acess Widgets
                Group {
                    ComfyLabeledStepper(
                        "Distance From Left (Top Row)",
                        value: $settings.quickAccessWidgetDistanceFromLeft,
                        in: -50...50,
                        step: 1
                    )
                }
                .padding(.horizontal, 22)
                
                if self.notchWidthChanged {
                    Text("Changes detected. Save and reopen the notch to apply.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
                
                /// Reset Button, Add A Revert As Well If Reset Pressed
                HStack(spacing: 8) {
                    Button(action: {
                        if resetPressed { return }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.lastNotchWidth = settings.notchMaxWidth
                            settings.notchMaxWidth = 710
                            notchWidthStep = 1.0
                        }
                        resetPressed = true
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    if resetPressed {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                settings.notchMaxWidth = lastNotchWidth
                                resetPressed = false
                                notchWidthStep = 1.0
                            }
                        }) {
                            Text("Revert")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
            }
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
                ComfyLabeledStepper(
                    "Scroll Speed",
                    value: $settings.nowPlayingScrollSpeed,
                    in: 1...100,
                    step: 1
                )
                .padding(.vertical, 7)
                
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
