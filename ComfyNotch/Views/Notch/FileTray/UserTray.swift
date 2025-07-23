//
//  UserTray.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/23/25.
//

import SwiftUI

struct UserTray: View {
    @EnvironmentObject var fileDropManager : FileDropManager
    @EnvironmentObject var viewModel       : FileTrayViewModel
    
    @ObservedObject var notchStateManager: NotchStateManager = .shared
    
    
    @Binding var showDeleteFileAlert: Bool
    @Binding var currentDeleteFileURL: URL?
    
    var body: some View {
        HStack {
            let columns = [
                GridItem(.adaptive(minimum: 100))
            ]
            
            ComfyScrollView {
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(fileDropManager.droppedFiles.filter { FileManager.default.fileExists(atPath: $0.path) }, id: \.self) { fileURL in
                        showFile(for: fileURL)
                    }
                }
            }
        }
    }
    
    // MARK: - Show File
    @ViewBuilder
    func showFile(for fileURL: URL) -> some View {
        VStack(spacing: 0) {
            viewModel.showFileThumbnail(fileURL: fileURL)
            
            HStack(spacing: 4) {
                showTimeStamp(fileURL: fileURL)
                    .font(.caption2)
                    .foregroundColor(.gray)
                showMenu(fileURL: fileURL)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            
            viewModel.showFileName(fileURL: fileURL, fileDropManager: fileDropManager)
        }
    }
    
    // MARK: - Show Time Stamp
    @ViewBuilder
    func showTimeStamp(fileURL: URL) -> some View {
        Text(fileDropManager.getFormattedTimestamp(for: fileURL))
            .foregroundColor(.secondary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.3))
            )
    }
    
    // MARK: - Show Menu
    @ViewBuilder
    func showMenu(fileURL: URL) -> some View {
        Menu {
            Button("Preview") {
                openFile(fileURL: fileURL)
            }
            Button("Share via AirDrop") {
                share(fileURL: fileURL)
            }
            Button("Delete", role: .destructive) {
                activateDelete(fileURL: fileURL)
            }
        } label: {
            Image(systemName: "ellipsis.circle") // or something less triangle-prone
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
    }
    
    func share(fileURL: URL) {
        AppSwitcherManager.switchToUI()
        
        let service = NSSharingService(named: .sendViaAirDrop)
        service?.perform(withItems: [fileURL])
        
        // Delay hiding again until AirDrop panel likely closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            AppSwitcherManager.switchToAccessory()
        }
    }
    
    func activateDelete(fileURL: URL) {
        showDeleteFileAlert = true
        currentDeleteFileURL = fileURL
    }
    
    func openFile(fileURL: URL) {
        NSWorkspace.shared.open(fileURL)
        /// Close the file tray
        notchStateManager.currentPanelState = .home
        UIManager.shared.applyOpeningLayout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ScrollHandler.shared.closeFull()
        }
    }
}
