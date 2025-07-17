//
//  AnimationSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/28/25.
//

import SwiftUI

struct AnimationSettings: View {
    
    @ObservedObject var settings: SettingsModel
    
    var body: some View {
        ComfyScrollView {
            headerView
            
            ComfySection(title: "Notch Opening", isSub: true) {
                animationSettings
            }
            
            ComfySection(title: "Experimental Metal Rendering", hasDescription: true, isSub: true) {
                experimentalMetalRendering
            }
        }
    }
    
    // MARK: - HEADER
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Animation Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.top, 12)
    }

    
    // MARK: - Animation
    private var animationSettings: some View {
        VStack {
            openingAnimations
            
//            VStack(alignment: .leading, spacing: 8) {
//
//            }
        }
    }
    
    private var experimentalMetalRendering: some View {
        VStack {
            /// Warning about experimental
            HStack {
                Text("⚠️ Warning: This feature will increase memory usage and CPU usage")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.yellow.opacity(0.1))
            )
            
            /// Turn on and off metal animations
            HStack {
                VStack {
                    Text("Enable Metal Animations/Shaders")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Toggle("",isOn: $settings.enableMetalAnimation)
                    .toggleStyle(.switch)
                    .onChange(of: settings.enableMetalAnimation) { _, newValue in
                        settings.saveSettings()
                    }
            }
            .padding(.top, 10)
            
            
            /// if metal animations is enabled
            if settings.enableMetalAnimation {
                HStack {
                    Text("Notch Background Animation")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("", selection: $settings.notchBackgroundAnimation) {
                        ForEach(ShaderOption.allCases, id: \.self) { option in
                            Text(option.displayName)
                                .tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.accentColor)
                    .onChange(of: settings.notchBackgroundAnimation) {
                        settings.saveSettings()
                    }
                    .frame(width: 250)
                }
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(settings.enableMetalAnimation ? .interactiveSpring(duration: 0.3) : .none, value: settings.notchBackgroundAnimation)
                
                HStack {
                    Text("Constant 120 FPS")
                    Spacer()
                    
                    Toggle("", isOn: $settings.constant120FPS)
                        .toggleStyle(.switch)
                        .onChange(of: settings.constant120FPS) {
                            settings.saveSettings()
                        }
                    
                }
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(settings.enableMetalAnimation ? .interactiveSpring(duration: 0.3) : .none, value: settings.notchBackgroundAnimation)
            }

        }
    }
    
    private var openingAnimations: some View {
        VStack {
            HStack(spacing: 0) {
                Text("Opening Animation")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            
                Spacer()
                
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
                .frame(width: 250)
            }
            
            HStack {
                Text("Select how the notch opens when activated.")
                    .foregroundStyle(Color(.systemGray))
                    .font(.footnote)
                Spacer()
            }
        }
    }
    
}

#Preview {
    AnimationSettings(settings: SettingsModel.shared)
}
