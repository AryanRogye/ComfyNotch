import SwiftUI

struct FileTrayView: View {

    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared

    var body: some View {
        VStack(spacing: 0) {
            if animationState.isExpanded {
                let droppedFiles = self.getFilesFromStoredDirectory()
                if droppedFiles.isEmpty {
                    Text("No Files Yet")
                    Spacer()
                } else {
                    ScrollView {
                        ForEach(droppedFiles, id: \.self) { fileURL in
                            HStack {
                                Text(fileURL.lastPathComponent)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
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
                            .padding(.horizontal)
                        }
                    }
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
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
                if url.lastPathComponent.hasPrefix("DroppedImage") {
                    matchedFiles.append(url)
                }
            }
        } catch {
            print("There Was A Error Getting Paths \(error.localizedDescription)")
        }
        return matchedFiles
    }
}