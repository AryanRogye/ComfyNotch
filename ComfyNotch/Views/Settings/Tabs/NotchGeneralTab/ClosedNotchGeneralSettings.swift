//
//  ClosedNotchGeneralSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/17/25.
//

import SwiftUI

struct ClosedNotchValues {
    var notchMinWidth: Int = 290
    var hoverTargetMode : HoverTarget = .none
    var fallbackHeight: Int = 0
    var hudEnabled: Bool = false
    var oneFingerAction: TouchAction = .none
    var twoFingerAction: TouchAction = .none
}

struct ClosedNotchGeneralSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    @Binding var didChange: Bool
    @Binding var v: ClosedNotchValues
    
    init(values: Binding<ClosedNotchValues>, didChange: Binding<Bool> ) {
        self._didChange = didChange
        self._v = values
    }
    
    var body: some View {
        VStack {
            
            notchShapeClosed
                .padding([.horizontal, .top])

            Divider()
                .padding([.vertical, .top], 4)
            
            panelMinWidthSettings
                .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 4)
            
            fallbackHeightSettings
                .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 4)
            
            hoverSettings
                .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 4)
            
            hudSettings
                .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 4)
            
            touchSettings
                .padding(.vertical, 4)
                .padding(.bottom)
        }
        .onAppear {
            v.hoverTargetMode = settings.hoverTargetMode
            v.fallbackHeight = Int(settings.notchMinFallbackHeight)
            v.hudEnabled = settings.enableNotchHUD
            v.oneFingerAction = settings.oneFingerAction
            v.twoFingerAction = settings.twoFingerAction
            v.notchMinWidth = Int(settings.notchMinWidth)
        }
        .onChange(of: v.hoverTargetMode)  { checkDidChange() }
        .onChange(of: v.fallbackHeight)   { checkDidChange() }
        .onChange(of: v.hudEnabled)       { checkDidChange() }
        .onChange(of: v.oneFingerAction)  { checkDidChange() }
        .onChange(of: v.twoFingerAction)  { checkDidChange() }
        .onChange(of: v.notchMinWidth)    { checkDidChange() }
    }
    
    private func checkDidChange() {
        didChange =
        v.hoverTargetMode != settings.hoverTargetMode
        || v.fallbackHeight  != Int(settings.notchMinFallbackHeight)
        || v.hudEnabled      != settings.enableNotchHUD
        || v.oneFingerAction != settings.oneFingerAction
        || v.twoFingerAction != settings.twoFingerAction
        || v.notchMinWidth   != Int(settings.notchMinWidth)
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
                ComfyNotchShape(
                    topRadius: 8, bottomRadius: 14
                )
                    .fill(Color.black)
                    .allowsHitTesting(false)
            )
            /// this is cuz notch is 38 and image is 40, we push it up
            .padding(.top, -2)
        }
    }
    
    // MARK: - Notch Min Panel Width
    private var panelMinWidthSettings: some View {
        VStack(alignment: .leading) {
            ComfySlider(
                value: $v.notchMinWidth,
                in: Int(settings.MIN_NOTCH_MIN_WIDTH)...Int(settings.MAX_NOTCH_MIN_WIDTH),
                label: "Notch Width When Closed"
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Fallback Height Settings
    private var fallbackHeightSettings: some View {
        VStack(alignment: .leading) {
            ComfySlider(
                value: $v.fallbackHeight,
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
        .padding(.horizontal)
    }
    
    // MARK: - Hover Settings
    private var hoverSettings: some View {
        VStack {
            HStack {
                Text("Hover Activation Area")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Hover Target", selection: $v.hoverTargetMode) {
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
                
                Toggle("", isOn: $v.hudEnabled)
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
                Picker("One Finger Action", selection: $v.oneFingerAction) {
                    ForEach(TouchAction.allCases, id: \.self) { action in
                        Text(action.displayName)
                            .tag(action)
                    }
                }
                
                Picker("Two Finger Action", selection: $v.twoFingerAction) {
                    ForEach(TouchAction.allCases, id: \.self) { action in
                        Text(action.displayName)
                            .tag(action)
                    }
                }
            }
            
        }
        .padding([.horizontal])
    }
}
