//
//  EventRunner.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/30/25.
//

import SwiftUI

struct EventRunner: View, Widget {
    
    var name: String = "EventRunnerWidget"
    
    @StateObject private var eventRunnerState: EventRunnerState = .shared
    @State private var addPressed: Bool = false
    
    @State private var linkOrPath: String = ""
    
    var swiftUIView: AnyView {
        AnyView(self)
    }

    var body: some View {
        ZStack {
            if addPressed {
                addEventForRunner
            } else {
                myUserEvents
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var myUserEvents: some View {
        VStack {
            addTopRow
                .padding(.horizontal)
            userEvents
            Spacer()
        }
    }
    
    private var addEventForRunner: some View {
        VStack {
            /// Top Row With A Close
            closeAddEvents
                .padding(.horizontal)

            Divider()
            
            HStack {
                
                /// Select URL or Application
                Picker("URL or Application", selection: $linkOrPath) {
                    Text("URL").tag("url")
                    Text("Application").tag("app")
                }
                .labelsHidden()
                
                if linkOrPath != "" {
                    /// Add Icon
                    /// on selection i want to make sure i can check between
                    /// sf symbol and the actual icon that the application
                    /// could be
                    Button(action: {
                        
                    }) {
                        Image(systemName: "")
                            .resizable()
                            .frame(width: 10, height: 10)
                    }
                    
                    /// Path or Deeplink
                }
            }
            if linkOrPath != "" {
                /// Set Name
                TextField("Event Name", text: $linkOrPath)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }
            
            /// Save Button
            Spacer()
        }
        .background(Color.black.opacity(0.2))
//        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut, value: addPressed)
    }
    
    private var closeAddEvents: some View {
        HStack {
            Text("Add Events")
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    addPressed = false
                }
            }) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.red)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var userEvents: some View {
        /// Format will be icon, name  spacer()     path/link
        VStack {
            ForEach(eventRunnerState.events, id: \.self) { event in
                /// We Can Display Like This
            }
        }
    }
    
    /// Top Row Of the Event Runner Widget
    private var addTopRow: some View {
        HStack {
            Text("My Events")
            Spacer()
            Button(action: {
                /// Prompt User For Event Or Deeplink
                /// Most likely a Picker with both values
                withAnimation(.easeInOut(duration: 0.3)) {
                    addPressed = true
                }
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}


class EventRunnerState: ObservableObject {
    
    static let shared = EventRunnerState()
    /// We Can Store Events, this can either be
    /// run paths to the /Applications folder
    /// or we can also have deeplinks from other
    /// apps
    enum EventLink: Hashable {
        case runPath(String)
        case deepLink(String)
    }
    struct Event: Hashable {
        var icon: NSImage?
        var eventLink: EventLink
        var name: String
    }
    
    
    @Published var events: [Event] = []
    
    public func runEvent(_ event: Event) {
        switch event.eventLink {
        case .runPath(let path):
            NSWorkspace.shared.open(URL(fileURLWithPath: path))

        case .deepLink(let urlString):
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            } else {
                print("❌ Invalid deep link: \(urlString)")
            }
        }
    }
    
    /// Also Store Events in Memory
    public func saveEvent(_ event: Event) {
        
    }
    /// Collect Past Events From Memory
    public func loadEvents() {
        
    }
}
