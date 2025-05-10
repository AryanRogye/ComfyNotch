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
    
    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared
    
    @State var showDeleteFileAlert: Bool = false
    @State var currentDeleteFileURL: URL?
    @State var droppedFileInfo : FileInfo = FileInfo()
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 100))
        ]
        
        VStack(spacing: 0) {
            if animationState.isExpanded
            {
                Group {
                    /// Conditional to show the delete page
                    if !showDeleteFileAlert {
                        let droppedFiles = self.getFilesFromStoredDirectory()
                        /// If No Files
                        if droppedFiles.isEmpty {
                            
                        } else {
                            /// If Files Are There
                            HStack {
                                /// Add File Look
                                addFilesTray()
                                
                                    .padding(.horizontal, 10)
                                    .frame(width: 150, height: 150)
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
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 1) {
                                        ForEach(droppedFiles, id: \.self) { fileURL in
                                            showFile(for: fileURL)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(.white.opacity(0.5))
                                )
                                .frame(maxWidth: .infinity)
                                .padding(4)
                            }
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
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 2 : 0.1),
            value: animationState.isExpanded
        )
    }
    
    @ViewBuilder
    func addFilesTray() -> some View {
        VStack {
            if let dropped = animationState.droppedFile {
                VStack {
                    ScrollView {
                        showFileThumbnail(fileURL: dropped)
                        showFileName(fileURL: dropped)
                        
                        Text("Are file?")
                        HStack {
                            Button(action: {animationState.droppedFile = nil}) {
                                Image(systemName: "x.circle")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                            Button(action: {}) {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                        }
                        /// Description about the file
                        Text(String("Type: \(droppedFileInfo.realType)"))
                        Text("Dimensions: \(droppedFileInfo.dimensions ?? "No Size" )")
                        Text("Size(KB): \(droppedFileInfo.sizeInKB)")
                        Text("Created: \(droppedFileInfo.creationDate)")
                    }
                }
            } else {
                Text("Add Files Here")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
        }
        .onChange(of: animationState.droppedFile) { _, newValue in
            if let file = newValue {
                if let info = DroppedFileTracker.shared.extractFileInfo(from: file) {
                    self.droppedFileInfo = info
                }
            }
        }
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
    
    private func getTimestamp(fileURL: URL) -> Date {
        do {
            let resourceVlaues =  try fileURL.resourceValues(forKeys: [.creationDateKey])
            return resourceVlaues.creationDate ?? Date()
        } catch {
            debugLog("Error Getting Timestamp \(error.localizedDescription)")
        }
        return Date()
    }
    
    private func getFormattedTimestamp(for fileURL: URL) -> String {
        let createdAt = getTimestamp(fileURL: fileURL)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    private func getFormattedName(for fileURL: URL) -> String {
        let fileName = fileURL.lastPathComponent

        // Check if the filename contains "DroppedImage"
        guard let range = fileName.range(of: "DroppedImage") else {
            return fileName  // fallback: return original name if not found
        }

        // Cut everything after "DroppedImage"
        let afterPrefix = fileName[range.upperBound...]

        // Drop the extension
        return afterPrefix.split(separator: ".").first.map(String.init) ?? String(afterPrefix)
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
        Text(getFormattedTimestamp(for: fileURL))
    }
    
    @ViewBuilder
    func showFileName(fileURL: URL) -> some View {
        Text(getFormattedName(for: fileURL))
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func getFilesFromStoredDirectory() -> [URL] {
        let fileManager = FileManager.default
        let folderURL = settings.fileTrayDefaultFolder
        var matchedFiles: [URL] = []
        /// we wanna return the ones that start with a "DroppedImage" name
        /// This is the one that we added to that selected "Directory", if the user wants to remove
        /// or change the name then it wont show anymore and thats ok, thats up
        /// to them
        
        /// settings.fileTrayDefaultFolder is the folder to watch for
        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.hasPrefix("Dropped") {
                    matchedFiles.append(url)
                }
            }
        } catch {
            debugLog("There Was A Error Getting Paths \(error.localizedDescription)")
        }
        return matchedFiles
    }
}
