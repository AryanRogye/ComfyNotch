//
//  TopNotchCustomization.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct QuickAccessStyleValues {
    var quickAccessWidgetSimpleDynamic: QuickAccessType = .dynamic
}

struct QuickAccessStyleSettings: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Binding var didChange: Bool
    @Binding var values: QuickAccessStyleValues
    
    var body: some View {
        VStack {
            /// Show Top Notch Differences
            topNotchDifferences
                .padding(.bottom)
        }
        .onAppear {
            values.quickAccessWidgetSimpleDynamic = settings.quickAccessWidgetSimpleDynamic
        }
        .onChange(of: values.quickAccessWidgetSimpleDynamic.rawValue) { _, newValue in
            didChange = newValue != settings.quickAccessWidgetSimpleDynamic.rawValue
        }
    }
    
    private var topNotchDifferences: some View {
        VStack {
            HStack {
                Text("Pick a Top Control Style")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding([.top,.horizontal])
            
            Divider().padding(.vertical, 8)
            
            HStack {
                /// Option 1
                notchStyleButton(
                    type: .dynamic,
                    label: "Dynamic",
                    isSelected: values.quickAccessWidgetSimpleDynamic == .dynamic
                ) {
                    values.quickAccessWidgetSimpleDynamic = .dynamic
                } content: {
                    Option1()
                }
                
                /// Option 2
                notchStyleButton(
                    type: .simple,
                    label: "Simple",
                    isSelected: values.quickAccessWidgetSimpleDynamic == .simple
                ) {
                    values.quickAccessWidgetSimpleDynamic = .simple
                } content: {
                    Option2()
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    func notchStyleButton<Content: View>(
        type: QuickAccessType,
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: isSelected ? 5 : 0)
                    
                    content()
                        .padding(8) // uniform padding inside the box
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.plain)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}


struct Option1: View {
    private var segments: [(state: NotchViewState, icon: String, tooltip: String)] {
        let list: [(NotchViewState, String, String)] = [
            (.home,      "house",                   "Home"),
            (.file_tray, "tray.full",               "Files"),
            (.messages, "message",      "Messages"),
            (.utils,    "wrench.and.screwdriver", "Utilities")
        ]
        return list
    }
    
    // MARK: - View
    var body: some View {
        HStack {
            ForEach(segments, id: \.state) { seg in
                Button(action: {
                }) {
                    Image(systemName: seg.icon)
                        .foregroundStyle(
                            .white
                        )
                        .help(seg.tooltip)
                        .tag(seg.state)
                }
                .buttonStyle(.plain)
                .controlSize(.large)
            }
        }
        .frame(height: 22)
        
    }
}

struct Option2: View {
    
    private var width: CGFloat = 18
    private var height: CGFloat = 18
    
    var body: some View {
        HStack {
            homeButton
                .padding(.leading, 0)
            
            messagesButton
                .padding(.leading, 5)
            utilsButton
                .padding(.leading, 5)
            
            fileTrayButton
                .padding(.leading, 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Home Button
    
    private var homeButton: some View {
        Button(action: {
        }) {
            Image(systemName: "house")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(.blue)
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Messages Button
    
    private var messagesButton: some View {
        Button(action: {
        }) {
            Image(systemName: "message")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    .blue
                )
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Utils Button
    
    private var utilsButton: some View {
        Button(action: {
        } ) {
            Image(systemName: "wrench.and.screwdriver")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    .blue
                )
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - File Tray Button
    
    private var fileTrayButton: some View {
        Button(action: {
        }) {
            Image(systemName: "tray.full")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(
                    .blue
                )
                .padding(5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
    
}
