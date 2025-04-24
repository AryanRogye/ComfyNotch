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
            Color.black
                .clipShape(RoundedCornersShape(
                    topLeft: 0,
                    topRight: 0,
                    bottomLeft: cornerRadius,
                    bottomRight: cornerRadius
                ))
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
                        .padding(.bottom, 5)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onChange(of: PanelAnimationState.shared.isDroppingFiles) { _, hovering in
            if hovering && UIManager.shared.panelState == .closed {
                animationState.isExpanded = true
                ScrollHandler.shared.openFull()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedCornersShape(
                        topLeft: 0,
                        topRight: 0,
                        bottomLeft: cornerRadius,
                        bottomRight: cornerRadius
                 ))
        .mask(
            RoundedCornersShape(
                topLeft: 0,
                topRight: 0,
                bottomLeft: cornerRadius,
                bottomRight: cornerRadius
            )
        )
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
                        DispatchQueue.main.async {
                            PanelAnimationState.shared.droppedFiles.append(url)
                        }
                    } else {
                        print("❌ Failed to get file URL from provider")
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
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("DroppedImage-\(UUID().uuidString).png")
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
    
    @ViewBuilder
    private func renderFileTray() -> some View {
        VStack(spacing: 0) {
            if animationState.isExpanded {
                if animationState.droppedFiles.isEmpty {
                    Text("No Files Yet")
                    Spacer()
                } else {
                    ScrollView {
                        ForEach(animationState.droppedFiles, id: \.self) { fileURL in
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .padding(.top, animationState.isExpanded ? 10 : 0)
    }
}
