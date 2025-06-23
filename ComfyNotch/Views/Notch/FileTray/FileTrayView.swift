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
    
    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared
    
    @State var showDeleteFileAlert: Bool = false
    @State var currentDeleteFileURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            if animationState.isExpanded && !animationState.fileTriggeredTray
            {
                Group {
                    /// Conditional to show the delete page
                    if !showDeleteFileAlert {
                        /// If No Files
                        /// If Files Are There
                        HStack {
                            //                            /// Add File Look
                            addFilesTray
                                .padding(.horizontal, 10)
                                .frame(width: 150, height: 150)
                            /// This allows it to be blue when dragged over
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(animationState.isDroppingFiles ? Color.blue.opacity(0.8) : Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .animation(.easeInOut(duration: 0.3), value: animationState.isDroppingFiles)
                                )
                                .padding(.vertical, 5)
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            /// What Files Are There
                            userTray
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                            /// This allows it to be blue when dragged over
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(animationState.isDroppingFiles ? Color.blue.opacity(0.8) : Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .animation(.easeInOut(duration: 0.3), value: animationState.isDroppingFiles)
                                )
                                .padding(.vertical, 5)
                                .padding(.trailing, 10)
                        }
                    }
                    /// If Delete is pressed
                    else {
                        showPopup()
                    }
                }
                .transition(.opacity) // 👈 adds fade in/out
            }
        }
        .background(Color.clear)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 2 : 0.1),
            value: animationState.isExpanded
        )
    }
    
    private var userTray: some View {
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
    
    var addFilesTray: some View {
        VStack {
            /// TODO: This is really cool, maybe think about managing this better
            if let dropped = fileDropManager.droppedFileInfo, let droppedFile = fileDropManager.droppedFile {
                VStack {
                    ScrollView {
                        showFileThumbnail(fileURL: droppedFile)
                        showFileName(fileURL: droppedFile)
                        
                        //                        Text("Are file?")
                        //                        HStack {
                        //                            Button(action: {animationState.droppedFile = nil}) {
                        //                                Image(systemName: "x.circle")
                        //                                    .resizable()
                        //                                    .frame(width: 18, height: 18)
                        //                            }
                        //                            .buttonStyle(.plain)
                        //                            Button(action: {}) {
                        //                                Image(systemName: "checkmark")
                        //                                    .resizable()
                        //                                    .frame(width: 18, height: 18)
                        //                            }
                        //                            .buttonStyle(.plain)
                        //                        }
                        
                        showDroppedFileDescription(for: dropped)
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
    
    @ViewBuilder
    func showDroppedFileDescription(for dropped: FileInfo) -> some View {
        VStack {
            DisclosureGroup {
                Text("\(dropped.realType)")
            } label: {
                Text("Type")
            }
            
            DisclosureGroup {
                Text("\(dropped.dimensions ?? "No Size")")
                Text("\(dropped.sizeInKB)KB")
            } label: {
                Text("Dimensions")
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func showFile(for fileURL: URL) -> some View {
        VStack(spacing: 0) {
            showFileThumbnail(fileURL: fileURL)
            HStack(alignment: .center ,spacing: 0) {
                showFileName(fileURL: fileURL)
                showMenu(fileURL: fileURL)
            }
            .padding([.horizontal, .top], 5)
            
            showTimeStamp(fileURL: fileURL)
        }
    }
    
    @ViewBuilder
    func showMenu(fileURL: URL) -> some View {
        Menu {
            Button("delete") { activateDelete(fileURL: fileURL) }
            Button("show file") { openFile(fileURL: fileURL) }
            Button("share") { share(fileURL: fileURL) }
        } label: {
            Image(systemName: "ellipsis")
                .resizable()
                .rotationEffect(.degrees(90))
                .frame(width: 10, height: 13)
        }
        .buttonStyle(.plain)
    }
    
    func share(fileURL: URL) {
        AppModeSwitcher.switchToUI()
        
        let service = NSSharingService(named: .sendViaAirDrop)
        service?.perform(withItems: [fileURL])
        
        // Delay hiding again until AirDrop panel likely closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            AppModeSwitcher.switchToAccessory()
        }
    }
    
    func activateDelete(fileURL: URL) {
        showDeleteFileAlert = true
        currentDeleteFileURL = fileURL
    }
    
    func openFile(fileURL: URL) {
        NSWorkspace.shared.open(fileURL)
        /// Close the file tray
        animationState.currentPanelState = .home
        ScrollHandler.shared.closeFull()
    }
    
    @ViewBuilder
    func showFileThumbnail(fileURL: URL) -> some View {
        AsyncImage(url: fileURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure(_), .empty:
                Image(systemName: "doc.fill") // or "doc.text.fill", "doc.richtext", etc.
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(10)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onDrag {
            NSItemProvider(contentsOf: fileURL)!
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
                                    debugLog("There was an error deleting the file \(error.localizedDescription)")
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
    
    @ViewBuilder
    func showTimeStamp(fileURL: URL) -> some View {
        Text(fileDropManager.getFormattedTimestamp(for: fileURL))
    }
    
    @ViewBuilder
    func showFileName(fileURL: URL) -> some View {
        Text(fileDropManager.getFormattedName(for: fileURL))
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
