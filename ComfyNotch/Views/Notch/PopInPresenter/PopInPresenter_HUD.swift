//
//  PopInPresenter_Volume.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/23/25.
//

import SwiftUI

class PopInPresenter_HUD_Coordinator: ObservableObject {
    static let shared = PopInPresenter_HUD_Coordinator()
    
    @Published var isPresented: Bool = false
    /// Current Class That's calling htis
    var currentOwner: HUDOwner = .none
    
    enum HUDOwner {
        case none
        case brightness
        case volume
    }
    
    private var autoCloseTimer: Timer?
    
    func presentIfAllowed(for owner: HUDOwner, openBlock: () -> Void) {
        /// AutoCloseTimer because this means that some other could have called this
        /// and they would be still be viewing the content on the PopInPresenter_HUD view
        cancelAutoCloseTimer()
        if currentOwner == .none || currentOwner == owner {
            isPresented = true
            currentOwner = owner
            openBlock()

            autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.currentOwner == owner {
                    self.closeHUD()
                }
            }
        } else {
            print("⚠️ Ignored presentation for \(owner), current owner: \(currentOwner)")
        }
    }
    
    func closeHUD(force: Bool = false) {
        cancelAutoCloseTimer()
        if force || currentOwner != .none {
            isPresented = false
            currentOwner = .none
            DispatchQueue.main.async {
                NotchStateManager.shared.currentPopInPresentationState = .none
            }
            ScrollHandler.shared.peekClose()
        }
    }

    private func cancelAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }
}

struct PopInPresenter_HUD: View {
    
    @ObservedObject private var brightnessManager: BrightnessWatcher = .shared
    @ObservedObject private var volumeManager: VolumeManager = .shared
    @ObservedObject private var musicModel: MusicPlayerWidgetModel = .shared
    @ObservedObject var notchStateManager: NotchStateManager = .shared
    
    @State private var dominantColor: Color = .blue
    
    // Pre-computed constants
    private let hudWidth: CGFloat = 200
    private let spacing: CGFloat = 2
    private let animationDuration: Double = 0.08

    var body: some View {
        HStack(spacing: spacing) {
            HUDBar(
                icon: "speaker.wave.2.fill",
                color: dominantColor,
                fill: CGFloat(volumeManager.currentVolume)
            )
            Spacer()
            HUDBar(
                icon: "sun.max.fill",
                color: .yellow,
                fill: CGFloat(brightnessManager.currentBrightness)
            )
        }
        .frame(width: hudWidth, height: 30)
        .onAppear {
            dominantColor = Color(nsColor: musicModel.nowPlayingInfo.dominantColor)
        }
        .onChange(of: musicModel.nowPlayingInfo.dominantColor) { _, newColor in
            withAnimation(.easeOut(duration: 0.2)) {
                dominantColor = Color(nsColor: newColor)
            }
        }
    }
}

struct HUDBar: View {
    let icon: String
    let color: Color
    let fill: CGFloat
    
    // Pre-computed constants
    private let barWidth: CGFloat = 100
    private let barHeight: CGFloat = 15
    private let iconWidth: CGFloat = 20
    private let backgroundOpacity: Double = 0.15
    private let cornerRadius: CGFloat = 5
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: iconWidth, height: iconWidth)
                .imageScale(.medium)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white.opacity(backgroundOpacity))
                    
                    // Fill bar with smooth animation
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color)
                        .frame(width: geometry.size.width * max(0, min(fill, 1)))
                        .animation(.easeOut(duration: 0.1), value: fill)
                }
            }
            .frame(width: barWidth ,height: barHeight)
        }
    }
}
