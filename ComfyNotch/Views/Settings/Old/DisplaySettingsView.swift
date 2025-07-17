//
//  DisplaySettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/28/25.
//

import SwiftUI

struct DisplaySettingsView: View {
    
    @ObservedObject var settings: SettingsModel
    @ObservedObject var displayManager: DisplayManager = .shared

    var body: some View {
        ComfyScrollView {
            headerView
            
            ComfySection(title: "Display", isSub: true) {
                displaySection
            }
            
        }
    }
    
    // MARK: - HEADER
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Display Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.top, 12)
    }
    
    private var displaySection: some View {
        VStack {
            HStack {
                let columns = [
                    /// 2 displays Max
                    GridItem(.flexible(minimum: 100, maximum: 200)),
                    GridItem(.flexible(minimum: 100, maximum: 200)),
                ]
                Spacer()
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(displayManager.screenSnapshots.keys), id: \.self) { key in
                        if let image = displayManager.snapshot(for: key) {
                            let screen = NSScreen.screens.first(where: { $0.displayID == key })
                            VStack {
                                Text(displayManager.displayName(for: key))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 140)
                                    .cornerRadius(8)
                                    .padding(4)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Button(action: {
                                    displayManager.selectedScreen = screen
                                    displayManager.saveSettings()
                                }) {
                                    Text("Select")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(6)
                            .padding(.horizontal, 8)
                            .background(displayManager.selectedScreen ==  screen ? Color.primary.opacity(0.3) : Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            VStack(alignment: .center) {
                Text("Note that ComfyNotch will open the best on a window with a Notch")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                Text("A newly selected Display will need a relaunch to apply settings properly")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }


}
