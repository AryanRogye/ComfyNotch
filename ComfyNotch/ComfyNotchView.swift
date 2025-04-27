import AppKit
import SwiftUI
import Combine
import MetalKit
import UniformTypeIdentifiers   /// For the file drop

enum NotchViewState {
    case home
    case file_tray
    case utils
}

class PanelAnimationState: ObservableObject {
    


    static let shared = PanelAnimationState()

    @Published var isExpanded: Bool = false
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var songText: String = AudioManager.shared.currentSongText
    @Published var playingColor: NSColor = AudioManager.shared.dominantColor
    @Published var isDroppingFiles = false
    @Published var droppedFiles: [URL] = []
    

    @Published var currentPanelState: NotchViewState = .home
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
    
    @Binding private var isDroppingFiles: Bool
    @Binding private var droppedFiles: [URL]

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
                TopNotchView()
                    .environmentObject(widgetStore)
                
                /// see QuickAccessWidget.swift file to see how it works
                switch animationState.currentPanelState {
                case .home:         HomeNotchView().environmentObject(bigWidgetStore)
                case .file_tray:    FileTrayView()
                case .utils:        UtilsView()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            /// To make sure the notch doesnt go over the bottom of the screen
            .clipShape(
                RoundedCornersShape(
                    topLeft: 0,
                    topRight: 0,
                    bottomLeft: cornerRadius,
                    bottomRight: cornerRadius
                )
            )
        }
        /// MODIFIERS
        .onChange(of: PanelAnimationState.shared.isDroppingFiles) { _, hovering in
            if hovering && UIManager.shared.panelState == .closed {
                animationState.fileTriggeredTray = true
                animationState.currentPanelState = .file_tray
                animationState.isExpanded = true
                ScrollHandler.shared.openFull()
                
                /// We Reset THe FileTriggeredTray After a bit
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animationState.fileTriggeredTray = false
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}
