import SwiftUI

enum GeneralSettingsTab: CaseIterable {
    case dimensions, controls, touch, misc
    
    var title: String {
        switch self {
        case .dimensions: "Dimensions"
        case .controls:   "Controls"
        case .touch:      "Touch"
        case .misc:        "Misc"
        }
    }
    
    var icon: String {
        switch self {
        case .dimensions: "square.resize"
        case .controls:   "slider.horizontal.3"
        case .touch:      "hand.raised"
        case .misc:        "gearshape"
        }
    }
}

struct GeneralSettingsView: View {
    
    @ObservedObject var settings: SettingsModel
    @ObservedObject var notchSizeManager = NotchSizeManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedSaveHUD: Bool = false
    
    @State private var notchWidthStep: CGFloat = 1.0
    @State private var startNotchWidth: CGFloat? = nil
    @State private var notchWidthChanged: Bool = false
    @State private var lastNotchWidth: CGFloat = 0.0
    @State private var resetPressed: Bool = false
    
    private let maxWidgetCount = 3  // Limit to 3 widgets
    
    @State private var selectedTab: GeneralSettingsTab = .dimensions
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                saveSettingsButton
                    .padding([.top, .horizontal])
            }
            ComfyScrollView {
                headerView
                
                ComfySettingsTabBar(selectedTab: $selectedTab)
                
                Divider()
                
                Group {
                    switch selectedTab {
                    case .dimensions:
                        dimensionsSettings
                    case .controls:
                        controlsSettings
                    case .touch:
                        touchSettings
                    case .misc:
                        miscSettings
                    }
                }
                
                
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
    
    // MARK: - Dimension Settings
    private var dimensionsSettings: some View {
        ComfySection(title: "Dimensions", isSub: false) {
            notchSettings
        }
    }
    
    // MARK: - Controls Settings
    private var controlsSettings: some View {
        VStack {
            /// TODO: Look into hovering off and on toggles not really something i like but other users may not like it
            ComfySection(title: "Hover", isSub: false) {
                pickObjectHover
            }
            ComfySection(title: "Notch Pop-In", isSub: false) {
                scrollSpeed
                hudSettings
            }
        }
    }
    
    // MARK: - Touch Settings
    private var touchSettings: some View {
        ComfySection(title: "Touch Settings", isSub: false) {
            touchSettingsView
        }
    }
    
    // MARK: - Misc Settings
    private var miscSettings: some View {
        ComfySection(title: "Divider Settings", isSub: false) {
            Toggle("Enable Divider Between Widgets", isOn: $settings.showDividerBetweenWidgets)
                .onChange(of: settings.showDividerBetweenWidgets) {
                    settings.saveSettings()
                }
                .padding(.vertical, 8)
                .toggleStyle(.switch)
        }
    }
    
    
    // MARK: - Notch Settings
    private var notchSettings: some View {
        VStack {
            Group {
                ComfyLabeledStepper(
                    "Notch Height (Closed)",
                    value: Binding<Int>(
                        get: { Int(notchSizeManager.notchHeight) },
                        set: { newValue in
                            notchSizeManager.notchHeight = CGFloat(newValue)
                        }
                    ),
                    in: notchSizeManager.notchHeightMin...notchSizeManager.notchHeightMax,
                    step: 1
                )
                
                HStack(spacing: 6) {
                    Text("Default notch height: \(Int(notchSizeManager.getNotchHeightValues()))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    if notchSizeManager.getNotchHeightValues() != notchSizeManager.notchHeight {
                        Button("Reset") {
                            notchSizeManager.reset()
                        }
                        .font(.footnote)
                        .buttonStyle(.borderless)
                    }
                    
                    Button("Save") {
                        notchSizeManager.setNewNotchHeight(with: notchSizeManager.notchHeight)
                    }
                    .font(.footnote)
                    .buttonStyle(.borderless)

                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 22)
            
            Group {
                ComfyLabeledStepper(
                    "Notch Width (Expanded)",
                    value: $settings.notchMaxWidth,
                    in: settings.setNotchMinWidth...settings.setNotchMaxWidth,
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
    
    // MARK: - HUD Settings
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
    
    private var pickObjectHover: some View {
        VStack {
            HStack {
                Text("Hover Activation Area")
                    .font(.headline)
                
                Spacer()
                
                Picker("Hover Target", selection: $settings.hoverTargetMode) {
                    ForEach(HoverTarget.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .onChange(of: settings.hoverTargetMode) {
                    settings.saveSettings()
                    
                    if settings.hoverTargetMode == .panel {
                        PanelAnimator.shared.startAnimationListeners()
                    } else if settings.hoverTargetMode == .album {
                        PanelAnimator.shared.stopAnimationListeners()
                        /// The Album should manage it by listening to it inside the TopNotchView and ComfyNotchView
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Scroll Speed
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
    
    // MARK: - Touch View
    private var touchSettingsView: some View {
        VStack {
            GroupBox(label: Label("One-Finger Click", systemImage: "hand.tap")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose the action performed when you click with one finger while the notch is closed.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Picker("One-Finger Action", selection: $settings.oneFingerAction) {
                        ForEach(TouchAction.allCases, id: \.self) { action in
                            Text(action.displayName)
                                .tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settings.oneFingerAction) {
                        settings.saveSettings()
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox(label: Label("Two-Finger Click", systemImage: "hand.point.up.left")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose the action performed with a two-finger click while the notch is closed.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Picker("Two-Finger Action", selection: $settings.twoFingerAction) {
                        ForEach(TouchAction.allCases, id: \.self) { action in
                            Text(action.displayName)
                                .tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settings.twoFingerAction) {
                        settings.saveSettings()
                    }
                    
                }
                .padding(.vertical, 4)
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
