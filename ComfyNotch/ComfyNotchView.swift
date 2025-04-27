import AppKit
import SwiftUI
import Combine
import MetalKit
import UniformTypeIdentifiers   /// For the file drop

class PanelAnimationState: ObservableObject {
    static let shared = PanelAnimationState()

    @Published var isExpanded: Bool = false
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var songText: String = AudioManager.shared.currentSongText
    @Published var playingColor: NSColor = AudioManager.shared.dominantColor
    @Published var isDroppingFiles = false
    @Published var droppedFiles: [URL] = []
    
    @Published var isShowingFileTray = false
    /// This is used for iffffff the notch was opened by dragging
    /// we wanna show a cool animation for it getting activated so the user
    /// doesnt think its blue all the time lol
    @Published var fileTriggeredTray: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        AudioManager.shared.$currentSongText
            .receive(on: RunLoop.main)
            .sink { [weak self] newSong in
                self?.songText = newSong
            }
            .store(in: &cancellables)

        AudioManager.shared.$dominantColor
            .receive(on: RunLoop.main)
            .sink { [weak self] color in
                DispatchQueue.main.async {
                    self?.playingColor = color
                }
            }
            .store(in: &cancellables)
    }
}

struct ComfyNotchView: View {
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore

    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared
    @State private var isHovering: Bool = false /// Hovering for Pause or Play
    
    @Binding private var isDroppingFiles: Bool
    @Binding private var droppedFiles: [URL]

    private var paddingWidth: CGFloat = 20
    private var contentInset: CGFloat = 40
    private var cornerRadius: CGFloat = 20
    
    init() {
        let panelAnimationState = PanelAnimationState.shared
        let isDroppingFilesBinding = Binding<Bool>(
            get: { panelAnimationState.isDroppingFiles },
            set: { panelAnimationState.isDroppingFiles = $0 }
        )
        let droppedFilesBinding = Binding<[URL]> (
            get: { panelAnimationState.droppedFiles },
            set: { panelAnimationState.droppedFiles = $0 }
        )
        
        _isDroppingFiles = isDroppingFilesBinding
        _droppedFiles = droppedFilesBinding
    }

    var body: some View {
        ZStack {
            RoundedCornersShape(
                    topLeft: 0,
                    topRight: 0,
                    bottomLeft: cornerRadius,
                    bottomRight: cornerRadius
                )
                .fill(Color.black, style: FillStyle(eoFill: true))
                .contentShape(Rectangle()) // <- this makes the whole area droppable
                .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $isDroppingFiles) { providers in
                    handleDrop(providers: providers)
                }
            
            
            
            VStack(alignment: .leading,spacing: 0) {
                /// Compact Widgets
                renderTopRow()
                /// Big Widgets
                if !animationState.isShowingFileTray {
                    renderBottomWidgets()
                } else {
                    renderFileTray()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onChange(of: PanelAnimationState.shared.isDroppingFiles) { _, hovering in
            if hovering && UIManager.shared.panelState == .closed {
                animationState.fileTriggeredTray = true
                animationState.isShowingFileTray = true
                animationState.isExpanded = true
                ScrollHandler.shared.openFull()
                
                /// We Reset THe FileTriggeredTray After a bit
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animationState.fileTriggeredTray = false
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .clipShape(RoundedCornersShape(
//                        topLeft: 0,
//                        topRight: 0,
//                        bottomLeft: cornerRadius,
//                        bottomRight: cornerRadius
//                 ))
//        .mask(
//            RoundedCornersShape(
//                topLeft: 0,
//                topRight: 0,
//                bottomLeft: cornerRadius,
//                bottomRight: cornerRadius
//            )
//        )
        /// For Scrolling the Panel
        .panGesture(direction: .down) { delta, phase in
            ScrollHandler.shared.handlePan(delta: delta, phase: phase)
        }
        .panGesture(direction: .up) { delta, phase in
            ScrollHandler.shared.handlePan(delta: -delta, phase: phase)
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // File URL handling (e.g., from Finder)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                        
                        print("✅ Dropped file path: \(url.path)")

                        let renamedFile = "DroppedImage-\(UUID().uuidString)\(url.pathExtension.isEmpty ? "" : ".\(url.pathExtension)")"
                        let destURL = settings.fileTrayDefaultFolder.appendingPathComponent(renamedFile)

                        do {
                            try FileManager.default.copyItem(at: url, to: destURL)
                            print("📁 Copied to: \(destURL.path)")
                            DispatchQueue.main.async {
                                PanelAnimationState.shared.droppedFiles.append(destURL)
                            }
                        } catch {
                            print("❌ Failed to copy file: \(error)")
                        }
                    }
                }
            }

            // Screenshot or image (in-memory)
            else if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { object, error in
                    if let image = object as? NSImage {
                        print("📸 Received image from drag")

                        // Optional: Save image to temp dir
                        if let tiffData = image.tiffRepresentation,
                           let bitmap = NSBitmapImageRep(data: tiffData),
                           let pngData = bitmap.representation(using: .png, properties: [:]) {
                            let tempURL = settings.fileTrayDefaultFolder.appendingPathComponent("DroppedImage-\(UUID().uuidString).png")
                            do {
                                try pngData.write(to: tempURL)
                                print("✅ Saved image to: \(tempURL.path)")
                                DispatchQueue.main.async {
                                    PanelAnimationState.shared.droppedFiles.append(tempURL)
                                }
                            } catch {
                                print("❌ Failed to save image: \(error)")
                            }
                        }
                    }
                }
            }
        }

        return true
    }

    private func getNotchWidth() -> CGFloat {
        guard let screen = NSScreen.main else { return 180 } // Default to 180 if it fails

        let screenWidth = screen.frame.width

        // Rough estimates based on Apple specs
        if screenWidth >= 3456 { // 16-inch MacBook Pro
            return 180
        } else if screenWidth >= 3024 { // 14-inch MacBook Pro
            return 160
        } else if screenWidth >= 2880 { // 15-inch MacBook Air
            return 170
        }

        // Default if we can't determine it
        return 180
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
    
    @ViewBuilder
    private func renderFileTray() -> some View {
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
                                    PanelAnimationState.shared.isShowingFileTray = false
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
    
    @ViewBuilder
    private func renderBottomWidgets() -> some View {
        VStack {
            if animationState.isExpanded {
                /// Big Panel Widgets
                ZStack {
                    Color.black.opacity(1)
                        .clipShape(RoundedCornersShape(
                            topLeft: 10,
                            topRight: 10,
                            bottomLeft: 10,
                            bottomRight: 10
                        ))
                    HStack(spacing: 0) {
                        ForEach(bigWidgetStore.widgets.indices, id: \.self) { index in
                            let widgetEntry = bigWidgetStore.widgets[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                                    .padding(.horizontal, 2)
                                    .frame(maxWidth: .infinity)
                                    .layoutPriority(1) // make them expand evenly
                                    .padding(.horizontal, 2)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
    }

    @ViewBuilder
    private func renderTopRow() -> some View {
        HStack(spacing: 0) {
            // Left Widgets
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(widgetStore.leftWidgetsShown.indices, id: \.self) { index in
                        let widgetEntry = widgetStore.leftWidgetsShown[index]
                        if widgetEntry.isVisible {
                            widgetEntry.widget.swiftUIView
                                .padding(.top, 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Spacer()
                .frame(width: PanelAnimationState.shared.isExpanded ? 400 : getNotchWidth())
                .padding([.trailing, .leading], paddingWidth)
            
            // Right Widgets
            ZStack(alignment: .leading) {
                if !isHovering {
                    HStack(spacing: 0) {
                        ForEach(widgetStore.rightWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.rightWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                                    .opacity(isHovering ? 0 : 1)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 0) {
                        //// If the widget is playing show pause
                        if animationState.songText != "No Song Playing" {
                            Button(action: AudioManager.shared.togglePlayPause ) {
                                Image(systemName: "pause.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 17, height: 15)
                                    .foregroundColor(Color(nsColor: animationState.playingColor))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 23)
                        }
                        /// if the widget is not playing show play
                        else {
                            Button(action: AudioManager.shared.togglePlayPause ) {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 17, height: 15)
                                    .foregroundColor(Color(nsColor: animationState.playingColor))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 23)
                        }
                    }
                }
            }
            .onHover { hover in
                if animationState.bottomSectionHeight == 0 {
                    isHovering = hover
                } else {
                    isHovering = false
                }
            }
        }
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: UIManager.shared.getNotchHeight(), alignment: .top)
        // .border(Color.white, width: 0.5)
        .padding(.top,
                 animationState.isExpanded
                 
                 ? (animationState.isShowingFileTray
                        /// This is to keep the Top Row Steady, if the filetray is showing
                        ? -1
                        /// This is when the fileTray is not showing and its just the widgets
                        /// should have a -1 padding height
                        /// Note: I realizes that having both being the same was the best in this case
                        /// Old Value used to be 10, so if soemthing is fucked change it back
                        : -1
                 )
                 /// This is when the panel is closed and we're just looking at it
                 : 1
        )
    }
}
