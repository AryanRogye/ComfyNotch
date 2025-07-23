//
//  AddFilesTray.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/23/25.
//

import SwiftUI

struct AddFilesTray: View {
    
    @EnvironmentObject var fileDropManager : FileDropManager
    @EnvironmentObject var viewModel       : FileTrayViewModel
    @EnvironmentObject var qrCodeManager: QRCodeManager

    @ObservedObject var notchStateManager: NotchStateManager = .shared
    
    @State private var hasStartedQRScanning: Bool = false
    @State private var isHoveringOverAddedFile: Bool = false
    @State private var hoverErrorStatus: QRCodeManager.QRCodeManagerError = .none
    
    var body: some View {
        Group {
            if hasStartedQRScanning {
                QRCodeView(
                    hasStartedQRScanning: $hasStartedQRScanning,
                    hoverErrorStatus: $hoverErrorStatus
                )
            } else {
                addFilesTray
            }
        }
    }
    
    // MARK: - Add Files Tray
    var addFilesTray: some View {
        VStack {
            /// TODO: This is really cool, maybe think about managing this better
            if let dropped = fileDropManager.droppedFileInfo, let droppedFile = fileDropManager.droppedFile {
                VStack {
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            VStack {
                                viewModel.showFileThumbnail(fileURL: droppedFile)
                                viewModel.showFileName(fileURL: droppedFile, fileDropManager: fileDropManager)
                            }
                            .overlay {
                                if isHoveringOverAddedFile {
                                    hoverView
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.15), value: isHoveringOverAddedFile)
                                }
                            }
                            .onHover { hover in
                                /// Safety check for the current panel
                                if notchStateManager.currentPanelState == .file_tray {
                                    isHoveringOverAddedFile = hover
                                } else {
                                    isHoveringOverAddedFile = false
                                }
                            }
                            
                            Divider()
                                .padding([.vertical], 2)
                                .padding(.horizontal)
                            showDroppedFileDescription(for: dropped)
                            
                            closeButton
                            
                        }
                    }
                }
            } else {
                Text("Add Files Here")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            //            Spacer()
        }
    }
    
    // MARK: - Hover View
    private var hoverView: some View {
        Button(action: {
            hasStartedQRScanning = true
            Task {
                self.hoverErrorStatus = await qrCodeManager.start()
            }
        }) {
            VStack {
                Text("QR Open")
                Image(systemName: "qrcode")
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.4))
        }
        .padding(.top, 2)
    }
    
    // MARK: - Show File Description
    @ViewBuilder
    func showDroppedFileDescription(for dropped: FileInfo) -> some View {
        VStack {
            HStack {
                Text("Type:")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(dropped.realType)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .font(.caption)
            
            if let dims = dropped.dimensions {
                HStack {
                    Text("Dimensions:")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    Text(dims)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .font(.caption)
            }
            Text(ByteFormatter.format(bytes: dropped.sizeInKB * 1024))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .font(.caption)
            
        }
    }
    
    // MARK: - Close Button
    private var closeButton: some View {
        VStack {
            if fileDropManager.droppedFile != nil {
                Spacer()
                HStack {
                    Button(action: fileDropManager.clear) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundStyle(.red)
                                .frame(width: 16, height: 16)
                                .padding(4)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.4))
            }
        }
        .zIndex(1) // Ensure the close button is on top
    }
}
