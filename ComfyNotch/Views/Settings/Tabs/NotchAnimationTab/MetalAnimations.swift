//
//  MetalAnimations.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct MetalAnimationValues: Equatable {
    var enableMetalAnimation: Bool = false
    var notchBackgroundAnimation: ShaderOption = .ambientGradient
    var constant120FPS: Bool = false
}

struct MetalAnimations: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @Binding var v: MetalAnimationValues
    
    init(values: Binding<MetalAnimationValues>, didChange: Binding<Bool>) {
        self._didChange = didChange
        self._v = values
    }
    
    private var currentState: MetalAnimationValues {
        return v
    }
    
    private var savedState: MetalAnimationValues {
        return MetalAnimationValues(
            enableMetalAnimation: settings.enableMetalAnimation,
            notchBackgroundAnimation: settings.notchBackgroundAnimation,
            constant120FPS: settings.constant120FPS
        )
    }
    
    var body: some View {
        VStack {
            /// Warning about experimental
            warningAboutMetal
                .padding([.horizontal, .top])
            
            Divider()
                .padding(.vertical, 8)
            
            /// Turn on and off metal animations
            enableMetalToggle
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            
            /// if metal animations is enabled
            if v.enableMetalAnimation {
                
                Divider()
                    .padding(.bottom, 8)
                
                notchBackgroundShader
                    .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)

                fpsToggle
                    .padding(.horizontal)
                    .padding(.bottom)
                
            }
            
        }
        .onAppear {
            v.enableMetalAnimation = settings.enableMetalAnimation
            v.notchBackgroundAnimation = settings.notchBackgroundAnimation
            v.constant120FPS = settings.constant120FPS
        }
        .onChange(of: currentState) { _, newValue in
            didChange = newValue != savedState
        }
    }
    
    private var warningAboutMetal: some View {
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
    }
    
    private var enableMetalToggle: some View {
        Toggle("Enable Metal Animations/Shaders",isOn: $v.enableMetalAnimation)
            .toggleStyle(.switch)
    }
    
    private var notchBackgroundShader: some View {
        HStack {
            Text("Notch Background Animation")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Picker("", selection: $v.notchBackgroundAnimation) {
                ForEach(ShaderOption.allCases, id: \.self) { option in
                    Text(option.displayName)
                        .tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(.accentColor)
            .frame(width: 250)
        }
        .padding(.top, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(settings.enableMetalAnimation ? .interactiveSpring(duration: 0.3) : .none, value: settings.notchBackgroundAnimation)
    }
    
    private var fpsToggle: some View {
        HStack {
            Text("Constant 120 FPS")
            Spacer()
            
            Toggle("", isOn: $v.constant120FPS)
                .toggleStyle(.switch)
            
        }
        .padding(.top, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(settings.enableMetalAnimation ? .interactiveSpring(duration: 0.3) : .none, value: settings.notchBackgroundAnimation)
    }
}
