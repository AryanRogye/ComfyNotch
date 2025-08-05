//
//  BrightnessNumber.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/5/25.
//

import SwiftUI
import Combine

struct BrightnessNumber: View, Widget {
    
    var name: String = "Brightness Number"
    var alignment: WidgetAlignment? = .left
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject var uiManagerBridge = UIManagerBridge.shared
    
    @State private var displayBrightness: Float = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        Text("\(Int(displayBrightness * 100))%")
            .font(.system(size: 12, weight: .regular, design: .default))
            .padding([.top, .leading], 4)
            .onAppear {
                displayBrightness = uiManagerBridge.brightness
            }
            .onChange(of: uiManagerBridge.brightness) { _, newValue in
                animateVolumeChange(to: newValue)
            }
    }
    
    private func animateVolumeChange(to targetValue: Float) {
        // Cancel any existing animation
        animationTimer?.invalidate()
        
        let startValue = displayBrightness
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
            
            displayBrightness = startValue + difference * easedProgress
            
            if currentFrame >= totalFrames {
                displayBrightness = targetValue // Ensure we end exactly at target
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
