//
//  ClosedNotchGeneralSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ClosedNotchGeneralSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    
    @State private var hoverTargetMode : HoverTarget = .none
    @State private var fallbackHeight: Int = 0
    @State private var hudEnabled: Bool = false
    @State private var oneFingerAction: TouchAction = .none
    @State private var twoFingerAction: TouchAction = .none
    
    // MARK: - Initial Values
    private var hoverTargetModeInitialValue: HoverTarget {
        settings.hoverTargetMode
    }
    private var fallbackHeightInitialValue: Int {
        Int(settings.notchMinFallbackHeight)
    }
    private var hudEnabledInitialValue: Bool {
        settings.enableNotchHUD
    }
    private var oneFingerActionInitialValue: TouchAction {
        settings.oneFingerAction
    }
    private var twoFingerActionInitialValue: TouchAction {
        settings.twoFingerAction
    }
    
    var body: some View {
        VStack {
            notchShapeClosed
            
            fallbackHeightSettings
            
            Divider()
                .padding()
            
            hoverSettings
            
            Divider()
                .padding()
            
            hudSettings
            
            Divider()
                .padding()
            
            touchSettings
        }
        .onAppear {
            hoverTargetMode = settings.hoverTargetMode
            fallbackHeight = Int(settings.notchMinFallbackHeight)
            hudEnabled = settings.enableNotchHUD
            oneFingerAction = settings.oneFingerAction
            twoFingerAction = settings.twoFingerAction
        }
        .onChange(of: hoverTargetMode)  { checkDidChange() }
        .onChange(of: fallbackHeight)   { checkDidChange() }
        .onChange(of: hudEnabled)       { checkDidChange() }
        .onChange(of: oneFingerAction)  { checkDidChange() }
        .onChange(of: twoFingerAction)  { checkDidChange() }
    }
    
    private func checkDidChange() {
        didChange = hoverTargetMode != hoverTargetModeInitialValue
        || fallbackHeight != fallbackHeightInitialValue
        || hudEnabled != hudEnabledInitialValue
        || oneFingerAction != oneFingerActionInitialValue
        || twoFingerAction != twoFingerActionInitialValue
    }
    
    // MARK: - Notch Shape Closed
    private var notchShapeClosed: some View {
        /// Notch Shape
        ZStack {
            Image("ScreenBackgroundNotch")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(spacing: 0) {
                HStack {
                    CompactAlbumWidget()
                        .padding(.leading, 5)
                    
                    Spacer()
                    
                    FancyMovingBars()
                }
            }
            .padding(.horizontal, 7)
            .frame(width: 320, height: 38)
            // MARK: - Actual Notch Shape
            .background(
                ComfyNotchShape(topRadius: 8, bottomRadius: 14)
                    .fill(Color.black)
            )
            /// this is cuz notch is 38 and image is 40, we push it up
            .padding(.top, -2)
        }
    }
    
    // MARK: - Fallback Height Settings
    private var fallbackHeightSettings: some View {
        VStack(alignment: .leading) {
            ComfySlider(
                value: $fallbackHeight,
                in: settings.notchHeightMin...settings.notchHeightMax,
                label: "Notch Height Fallback"
            )
            /// TODO: 0 Point is too far to the leftit -m
            
            Text("""
                Use this value as the notch height when `safeAreaInsets` are unavailable—for example, on Intel Macs without a built‑in notch. It ensures consistent layout by providing a fallback height in points.
            """)
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(alignment: .center)
            .padding(.top, 2)
        }
        .padding([.horizontal, .top])
    }
    
    // MARK: - Hover Settings
    private var hoverSettings: some View {
        VStack {
            HStack {
                Text("Hover Activation Area")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Hover Target", selection: $hoverTargetMode) {
                    ForEach(HoverTarget.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding([.horizontal])
    }
    
    // MARK: - HUD Settings
    private var hudSettings: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Enable HUD")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $hudEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
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
        }
        .padding(.horizontal)
    }
    
    
    
    
    
    // MARK: - Touch Settings
    private var touchSettings: some View {
        VStack(alignment: .leading) {
            HStack {
                Picker("One Finger Action", selection: $oneFingerAction) {
                    ForEach(TouchAction.allCases, id: \.self) { action in
                        Text(action.displayName)
                            .tag(action)
                    }
                }
                
                Picker("Two Finger Action", selection: $twoFingerAction) {
                    ForEach(TouchAction.allCases, id: \.self) { action in
                        Text(action.displayName)
                            .tag(action)
                    }
                }
            }
            
        }
        .padding([.horizontal, .top])
    }
}
