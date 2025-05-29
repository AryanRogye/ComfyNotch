//
//  PopInPresenter_Messages.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/29/25.
//

import SwiftUI

struct PopInPresenter_Messages: View {
    
    @State private var latestHandle: MessagesManager.Handle?
    @State private var isLoading = true
    
    @State private var isHovering: Bool = false
    @State private var hoverTimer: Timer?

    @StateObject private var messagesManager: MessagesManager = .shared
    
    var body: some View {
        VStack {
            if isLoading {
                /// Loading View if the latest handle is being fetched
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.top, 20)
            } else if let handle = latestHandle {
                ZStack {
                    HStack {
                        /// Show Image of the User
                        Image(nsImage: handle.image)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                        Spacer()
                        /// Show the latest message from the user
                        Text(handle.lastMessage)
                    }
                    
                    if isHovering {
                        Text("IS HOVERING")
                    }
                }
            } else {
                Text("No messages")
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 40)
        .clipped()
        .padding(.horizontal, 20)
        .task {
            await loadLatestHandle()
        }
        .onHover { hovering in
            if hovering {
                isHovering = true
                hoverTimer?.invalidate()
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    Task { @MainActor in
                        messagesManager.restartMessagesPanelTimer()
                    }
                }
                RunLoop.main.add(hoverTimer!, forMode: .common)
            } else {
                isHovering = false
                hoverTimer?.invalidate()
                hoverTimer = nil
            }
        }
        
    }

    private func loadLatestHandle() async {
        // Move the heavy work to a background thread
        let handle = await Task.detached {
            await MessagesManager.shared.getLatestHandle()
        }.value

        await MainActor.run {
            self.latestHandle = handle
            self.isLoading = false
        }
    }
}
