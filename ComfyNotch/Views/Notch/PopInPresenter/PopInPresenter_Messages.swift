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
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.top, 20)
            } else if let handle = latestHandle {
                HStack {
                    Image(nsImage: handle.image)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                    Spacer()
                    Text(handle.lastMessage)
                }
            } else {
                Text("No messages")
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 30)
        .clipped()
        .padding(.horizontal, 20)
        .task {
            await loadLatestHandle()
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
