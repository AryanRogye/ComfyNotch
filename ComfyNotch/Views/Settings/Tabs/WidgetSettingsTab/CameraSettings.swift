//
//  CameraSettings.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI
import AVFoundation

struct CameraSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack {
            flipCamera
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider().groupBoxStyle()
            
            cameraQuality
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider().groupBoxStyle()

            cameraOverlay
                .padding(.horizontal)
                .padding(.vertical, 8)

            if settings.enableCameraOverlay {
                
                Divider().groupBoxStyle()
                
                overlayTimer
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Flip Camera
    private var flipCamera: some View {
        HStack {
            Text("Flip Camera")
                .font(.body)
            Spacer()
            Toggle("", isOn: $settings.isCameraFlipped)
                .labelsHidden()
                .onChange(of: settings.isCameraFlipped) { settings.saveSettings() }
                .toggleStyle(.switch)
        }
    }

    // MARK: - Camera Quality
    private var cameraQuality: some View {
        Picker("Camera Quality", selection: $settings.cameraQualitySelection) {
            Text("4K (3840×2160)").tag(AVCaptureSession.Preset.hd4K3840x2160)
            Text("Full HD (1920×1080)").tag(AVCaptureSession.Preset.hd1920x1080)
            Text("HD (1280×720)").tag(AVCaptureSession.Preset.hd1280x720)
            Text("High (Auto)").tag(AVCaptureSession.Preset.high)
            Text("Medium (640×480)").tag(AVCaptureSession.Preset.medium)
            Text("Low (352×288)").tag(AVCaptureSession.Preset.low)
            Text("Photo (Still Only)").tag(AVCaptureSession.Preset.photo)
        }
        .onChange(of: settings.cameraQualitySelection) {
            settings.saveSettings()
        }
    }

    // MARK: - Camera Overlay
    private var cameraOverlay: some View {
        HStack {
            Text("Enable Camera Overlay")
                .font(.body)
            Spacer()
            Toggle("", isOn: $settings.enableCameraOverlay)
                .labelsHidden()
                .onChange(of: settings.enableCameraOverlay) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        settings.saveSettings()
                    }
                }
                .toggleStyle(.switch)
        }
    }

    private var overlayTimer: some View {
        ComfySlider(
            value: $settings.cameraOverlayTimer,
            in: 5...120,
            step: 1,
            label: "Overlay Timer"
        )
            .transition(.opacity)
            .onChange(of: settings.cameraOverlayTimer) {
                settings.saveSettings()
            }
    }
}
