//
//  QuickAccessSettingsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/10/25.
//

import SwiftUI

struct QuickAccessSettingsView: View {
    
    @ObservedObject var settings: SettingsModel
    @State private var selected: Int = 0
    
    let widgetPreviews: [(title: String, view: AnyView)] = [
        ("Music Player Widget", AnyView(MusicPlayerWidget())),
        ("Event Widget", AnyView(EventWidget())),
        ("AI Chat Widget", AnyView(AIChatWidget())),
        ("Time Widget", AnyView(TimeWidget())),
        ("Notes Widget", AnyView(NotesWidget())),
        ("Camera Widget", AnyView(CameraWidget()))
        // Omit CameraWidget if you don’t want to preview it
    ]
    
    /// Constant Values
    var imageSize: CGFloat = 60
    
    var body: some View {
        ComfyScrollView {
            /// Show Display Of The Icons
            iconDisplay
            
            switch selected {
            case 0: homeView
            case 1: messagesView
            case 2: utilsView
            case 3: fileTrayView
            default: EmptyView()
            }
            
            Spacer()
        }
    }
    
    var fileTrayView: some View {
        VStack {
            Text("FileTray Settings")
            Spacer()
        }
    }
    
    var utilsView: some View {
        VStack {
            Text("Utils Settings")
            Spacer()
        }
    }
    
    var messagesView: some View {
        VStack {
            Text("Messages Settings")
            Spacer()
        }
    }
    
    var homeView: some View {
        VStack {
            Text("Home Settings")
                .font(.largeTitle)
            
            ComfySection(title: "Widgets") {
                // Music Widget - Single Row
                VStack(alignment: .leading, spacing: 8) {
                    Text("Music Player Widget")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    MusicPlayerWidget()
                        .padding(.bottom, 5)
                        .modifier(WidgetCardStyle())
                        .padding(.horizontal)
                }
                
                // Other Widget Previews in a Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 20)], spacing: 24) {
                    ForEach(widgetPreviews.dropFirst(), id: \.title) { widget in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(widget.title)
                                .font(.headline)
                                .padding(.leading, 5)
                            widget.view
                                .disabled(widget.title == "Notes Widget" ? false : true)
                                .padding(5)
                                .modifier(WidgetCardStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 80)

            Spacer()
        }
    }
    
    var iconDisplay: some View {
        HStack {
            /// Show 4 Icons
            Button(action: {
                withAnimation(.interactiveSpring(duration: 0.3)) {
                    selected = 0
                }
            }) {
                Image(systemName: "house")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                    .foregroundStyle(selected == 0 ? .blue : .white)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                withAnimation(.interactiveSpring(duration: 0.3)) {
                    selected = 1
                }
            }) {
                Image(systemName: "message")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                    .foregroundStyle(selected == 1 ? .blue : .white)
            }
            .buttonStyle(.plain)
            
            Spacer()

            Button(action: {
                withAnimation(.interactiveSpring(duration: 0.3)) {
                    selected = 2
                }
            }) {
                Image(systemName: "wrench.and.screwdriver")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                    .foregroundStyle(selected == 2 ? .blue : .white)
            }
            .buttonStyle(.plain)
            
            Spacer()

            Button(action: {
                withAnimation(.interactiveSpring(duration: 0.3)) {
                    selected = 3
                }
            }) {
                Image(systemName: "tray.full")
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                    .foregroundStyle(selected == 3 ? .blue : .white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: 180)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(20)
    }
    
    
}

struct WidgetCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 200)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
    }
}
