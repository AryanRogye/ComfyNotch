//
//  VolumeNumber.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/4/25.
//

import SwiftUI

struct VolumeNumber: View, Widget {
    
    var name: String = "Volume Number"
    var alignment: WidgetAlignment? = .left
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject private var volumeManager: VolumeManager = .shared
    
    @State private var displayedVolume: Float = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        Text("\(Int(displayedVolume * 100))%")
            .padding(.top, 4)
            .padding(.leading, 8)
            .onAppear {
                displayedVolume = volumeManager.currentVolume
            }
            .onChange(of: volumeManager.currentVolume) { _, newValue in
                animateVolumeChange(to: newValue)
            }
    }
    
    private func animateVolumeChange(to targetValue: Float) {
        // Cancel any existing animation
        animationTimer?.invalidate()
        
        let startValue = displayedVolume
        let difference = targetValue - startValue
        let duration: TimeInterval = 0.1 // Total animation duration
        let frameRate: TimeInterval = 1.0 / 60.0 // 60 FPS
        let totalFrames = Int(duration / frameRate)
        
        var currentFrame = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { timer in
            currentFrame += 1
            let progress = Float(currentFrame) / Float(totalFrames)
            
            // Use easing function for smoother animation
            let easedProgress = easeOut(progress)
            
            displayedVolume = startValue + difference * easedProgress
            
            if currentFrame >= totalFrames {
                displayedVolume = targetValue // Ensure we end exactly at target
                timer.invalidate()
                animationTimer = nil
            }
        }
    }
    
    // Ease-out function for smoother animation
    private func easeOut(_ t: Float) -> Float {
        return 1 - pow(1 - t, 3)
    }
}
