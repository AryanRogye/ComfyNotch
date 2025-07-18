//
//  ComfySettingsTabBar.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/6/25.
//

import SwiftUI

struct ComfySettingsTabBar: View {
    @Binding var selectedTab: GeneralSettingsTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(GeneralSettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(
                        selectedTab == tab
                        ? Color.accentColor.opacity(0.1)
                        : Color.clear
                    )
                    .cornerRadius(8)                     // round that full label area
                    .contentShape(Rectangle())           // make that full rectangle hit-testable
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}
