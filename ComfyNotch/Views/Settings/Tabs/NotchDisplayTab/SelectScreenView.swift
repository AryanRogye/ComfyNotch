//
//  SelectScreenView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct SelectScreenView: View {
    
    @ObservedObject var displayManager = DisplayManager.shared
    
    @State private var startScreen: NSScreen? = nil
    @State private var newScreen: NSScreen? = nil
    @State private var isApplying = false
    
    private var hasChanges: Bool {
        guard let startScreen, let newScreen else { return false }
        return !screensEqual(startScreen, newScreen)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            screens()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ComfyNotch works best with a screen that has a physical notch.")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding([.bottom, .horizontal])
        }
        .padding(.horizontal)
        .animation(.spring,  value: hasChanges)
        .onAppear {
            startScreen = displayManager.selectedScreen
        }
        .safeAreaInset(edge: .top) {
            if hasChanges {
                HStack(spacing: 12) {
                    // Staged label
                    if let ns = newScreen {
                        Text("Staged: \(ns.localizedName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Revert") {
                        newScreen = startScreen
                    }
                    .controlSize(.large)
                    
                    Button {
                        isApplying = true
                        displayManager.selectedScreen = newScreen
                        displayManager.saveSettings()
                        startScreen = newScreen
                        isApplying = false
                    } label: {
                        if isApplying {
                            ProgressView()
                                .controlSize(.regular)
                                .padding(.horizontal, 8)
                        } else {
                            Text("Apply")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(newScreen == nil)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 340), spacing: 16, alignment: .top)
    ]
    
    
    @inline(__always)
    private func screensEqual(_ a: NSScreen?, _ b: NSScreen?) -> Bool {
        a?.displayID == b?.displayID
    }

    private func screens() -> some View {
        
       return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(displayManager.screenSnapshots.keys), id: \.self) { key in
                if let image = displayManager.snapshot(for: key) {
                    
                    let screen = NSScreen.screens.first(where: { $0.displayID == key })
                    
                    let isCommitted = screensEqual(screen, displayManager.selectedScreen)
                    let isStaged   = screensEqual(screen, newScreen) && !isCommitted
                    
                    screenView(key: key, image: image, screen: screen)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    displayManager.selectedScreen == screen
                                    ? Color.accentColor.opacity(0.15)
                                    : isStaged ? Color.yellow.opacity(0.16) : Color.primary.opacity(0.05)
                                )
                        )
                        .overlay( // subtle selection ring
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    displayManager.selectedScreen == screen
                                    ? Color.accentColor
                                    : isStaged ? Color.yellow : Color.primary.opacity(0.08),
                                    lineWidth: displayManager.selectedScreen == screen ? 1.5 : 1
                                )
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture { newScreen = screen }
                }
            }
            .padding()
        }
    }
    
    private func screenView(key: CGDirectDisplayID, image: NSImage, screen: NSScreen?) -> some View {
        VStack {
            Text(displayManager.displayName(for: key))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 220, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button("Select") {
                newScreen = screen
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
