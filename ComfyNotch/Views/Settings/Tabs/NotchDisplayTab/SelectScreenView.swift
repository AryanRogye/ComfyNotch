//
//  SelectScreenView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/18/25.
//

import SwiftUI

struct SelectScreenView: View {
    
    @ObservedObject var displayManager = DisplayManager.shared
    
    private let columns = [
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 100, maximum: 200))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(displayManager.screenSnapshots.keys), id: \.self) { key in
                    if let image = displayManager.snapshot(for: key) {
                        let screen = NSScreen.screens.first(where: { $0.displayID == key })
                        
                        VStack(spacing: 8) {
                            Text(displayManager.displayName(for: key))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                                )
                            
                            Button("Select") {
                                displayManager.selectedScreen = screen
                                displayManager.saveSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    displayManager.selectedScreen == screen
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.primary.opacity(0.05)
                                )
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ComfyNotch works best with a screen that has a physical notch.")
                Text("A relaunch is required to fully apply changes after switching displays.")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding([.bottom, .horizontal])
        }
        .padding(.horizontal)
    }
}
