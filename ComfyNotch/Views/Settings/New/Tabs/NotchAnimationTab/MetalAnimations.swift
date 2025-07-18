//
//  MetalAnimations.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct MetalAnimations: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    
    var body: some View {
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
}
