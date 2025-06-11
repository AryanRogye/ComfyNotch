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

    @ObservedObject private var messagesManager: MessagesManager = .shared
    
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
                        Button(action: {
                            openNotchToMessage()
                        }) {
                            Label("Open Message", systemImage: "arrow.up.right")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = true
                }
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
    
    private func openNotchToMessage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UIManager.shared.applyOpeningLayout()
            ScrollHandler.shared.peekClose()
            PanelAnimationState.shared.currentPanelState = .home
            PanelAnimationState.shared.currentPopInPresentationState = .none
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            PanelAnimationState.shared.isExpanded = true
            ScrollHandler.shared.openFull()
        }
        /// WARNING: 2.3 -> onwards is the perfect delay to avoid a jittering
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            PanelAnimationState.shared.currentPanelState = .messages
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
