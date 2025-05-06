import SwiftUI
import AppKit

struct FileRow: View {
    let fileURL: URL
    
    var body: some View {
        HStack {
                ShareLink(item: fileURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
        }
    }
}
struct FileTrayView: View {

    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared
    
    @State var showDeleteFileAlert: Bool = false
    @State var currentDeleteFileURL: URL?
    

    var body: some View {
        VStack(spacing: 0) {
            if animationState.isExpanded {
                if !showDeleteFileAlert {
                    let droppedFiles = self.getFilesFromStoredDirectory()
                    if droppedFiles.isEmpty {
                        Text("No Files Yet")
                            .font(.headline)
                            .padding(.leading, 5)
                        Spacer()
                    } else {
                        ScrollView {
                            ForEach(droppedFiles, id: \.self) { fileURL in
                                HStack {
                                    showFileName(fileURL: fileURL)
                                        .frame(maxWidth: 200)
                                    showTimeStamp(fileURL: fileURL)
                                    
                                    Spacer()
//                                    FileRow(fileURL: fileURL)
                                    showFile(fileURL: fileURL)
                                    showDelete(fileURL: fileURL)
                                }
                                .padding(.horizontal)
                                .onDrag {
                                    NSItemProvider(contentsOf: fileURL)!
                                }
                            }
                        }
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    showPopup()
                }
            }
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
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
                            do {
                                try FileManager.default.removeItem(at: currentDeleteFileURL!)
                            } catch {
                                debugLog("There was a error deleting the file \(error.localizedDescription)")
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
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.middle)
    }
    
    @ViewBuilder
    func showFile(fileURL: URL) -> some View {
        Button(action: {
            NSWorkspace.shared.open(fileURL)
            /// Close the file tray
            animationState.currentPanelState = .home
            ScrollHandler.shared.closeFull()
        }) {
            Image(systemName: "eye")
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func showDelete(fileURL: URL) -> some View {
        Button(action: {
            showDeleteFileAlert = true
            currentDeleteFileURL = fileURL
        }) {
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
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
