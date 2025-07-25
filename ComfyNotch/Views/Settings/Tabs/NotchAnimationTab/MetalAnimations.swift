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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16, weight: .bold))
                .padding(.top, 2)
            
            Text("Enabling this feature may increase memory and CPU usage.")
                .font(.footnote)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.yellow.opacity(0.18), lineWidth: 1)
                )
        )
    }
    
    private var enableMetalToggle: some View {
        Toggle("Enable Metal Animations/Shaders",isOn: $v.enableMetalAnimation)
            .toggleStyle(.switch)
    }
    
    private var notchBackgroundShader: some View {
        HStack {
            Picker("Notch Background Animation", selection: $v.notchBackgroundAnimation) {
                ForEach(ShaderOption.allCases, id: \.self) { option in
                    Text(option.displayName)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.accentColor)
        }
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
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(settings.enableMetalAnimation ? .interactiveSpring(duration: 0.3) : .none, value: settings.notchBackgroundAnimation)
    }
}
