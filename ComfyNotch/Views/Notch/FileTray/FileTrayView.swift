import SwiftUI
import AppKit

struct FileRow: View {
    let fileURL: URL
    
    var body: some View {
        Button(action: {
        }) {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .frame(width: 12, height: 15)
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
    }
}

struct FileTrayView: View {
    
    @EnvironmentObject var fileDropManager : FileDropManager
    
    @ObservedObject var notchStateManager = NotchStateManager.shared
    @ObservedObject var uiManager = UIManager.shared
    @ObservedObject var settings = SettingsModel.shared
    
    @StateObject private var viewModel: FileTrayViewModel = FileTrayViewModel()
    
    @State var showDeleteFileAlert: Bool = false
    @State var currentDeleteFileURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            if uiManager.panelState == .open && !fileDropManager.shouldAutoShowTray
            {
                Group {
                    if showDeleteFileAlert {
                        /// Delete View
                        showPopup()
                    }
                    else {
                        /// Main View
                        fileTray
                            .padding(.bottom, 8)
                    }
                }
                .transition(.opacity)
            }
        }
        .environmentObject(viewModel)
        .animation(
            .easeInOut(duration: uiManager.panelState == .open ? 2 : 0.1),
            value: uiManager.panelState == .open
        )
    }
    
    private var fileTray: some View {
        HStack {
            VStack {
            }
            /// Add File Look
            AddFilesTray()
                .padding(.horizontal, 10)
                .frame(width: 140)
                .frame(maxHeight: .infinity)
            /// This allows it to be blue when dragged over
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(fileDropManager.isDroppingFiles ? Color.blue.opacity(0.8) : Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.gray.opacity(0.5))
                        .animation(.easeInOut(duration: 0.3), value: fileDropManager.isDroppingFiles)
                )
                .padding(.leading, 10)
            
            Spacer()
            
            /// What Files Are There
            UserTray(showDeleteFileAlert: $showDeleteFileAlert, currentDeleteFileURL: $currentDeleteFileURL)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            /// This allows it to be blue when dragged over
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(fileDropManager.isDroppingFiles ? Color.blue.opacity(0.8) : Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.gray.opacity(0.5))
                        .animation(.easeInOut(duration: 0.3), value: fileDropManager.isDroppingFiles)
                )
                .padding(.trailing, 10)
        }
    }
    
    
    
    @ViewBuilder
    func showPopup() -> some View {
        if showDeleteFileAlert {
            ZStack {
                VStack(alignment: .center,spacing: 0) {
                    Text("are you sure you want to delete this file?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text(currentDeleteFileURL?.lastPathComponent ?? "Unknown File")
                    
                    HStack {
                        Button(action: { showDeleteFileAlert = false }) {
                            Image(systemName: "x.circle")
                                .resizable()
                                .foregroundStyle(.red)
                                .frame(width: 32, height: 32)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            if let url = currentDeleteFileURL {
                                do {
                                    try FileManager.default.removeItem(at: url)
                                } catch {
                                    debugLog("There was an error deleting the file \(error.localizedDescription)", from: .fileTray)
                                }
                            }
                            // call your delete function here
                            showDeleteFileAlert = false
                            currentDeleteFileURL = nil
                        }) {
                            Image(systemName: "checkmark")
                                .resizable()
                                .foregroundStyle(.green)
                                .frame(width: 32, height: 32)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: 200)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
