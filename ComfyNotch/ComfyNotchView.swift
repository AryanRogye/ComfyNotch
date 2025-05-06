import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

enum NotchViewState {
    case home
    case file_tray
    case utils
    case popInPresentation
}

struct Anim {
    // macOS 14+ bouncy spring; fallback to a cubic curve
    static var spring: Animation {
        if #available(macOS 14, *) {
            .spring(.bouncy(duration: 0.40))
        } else {
            .timingCurve(0.16, 1, 0.3, 1, duration: 0.70)
        }
    }
    
    /// What they call `.smooth` – a mild ease-out you can use for progress
    static let smooth = Animation.easeOut(duration: 0.15)
}

class PanelAnimationState: ObservableObject {
    
    static let shared = PanelAnimationState()

    @Published var isExpanded: Bool = false
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var currentPanelWidth: CGFloat = UIManager.shared.startPanelWidth
    @ObservedObject var musicModel: MusicPlayerWidgetModel = .shared
    @Published var isDroppingFiles = false
    @Published var droppedFiles: [URL] = []
    

    @Published var currentPanelState: NotchViewState = .home
    /// This is used for iffffff the notch was opened by dragging
    /// we wanna show a cool animation for it getting activated so the user
    /// doesnt think its blue all the time lol
    @Published var fileTriggeredTray: Bool = false

    private var cancellables = Set<AnyCancellable>()
}

struct ComfyNotchView: View {
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore

    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared
    
    @Binding private var isDroppingFiles: Bool
    @Binding private var droppedFiles: [URL]
    
    /// Testing:
    @State private var dragProgress: CGFloat = 0

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
                .contentShape(Rectangle())
                .offset(y: dragProgress * 12)
                .scaleEffect(1 + dragProgress * 0.03)
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
                case .popInPresentation: PopInPresenter()
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
        .onChange(of: UIManager.shared.panelState) { _, newState in
            if newState == .open {
                if PanelAnimationState.shared.currentPanelState == .popInPresentation {
                    PanelAnimationState.shared.currentPanelState = .home
                }
            }
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
        .panGesture(direction: .down) { translation, phase in
            
            guard UIManager.shared.panelState == .closed else { return }
            
            let threshhold : CGFloat = PanelAnimationState.shared.currentPanelState == .popInPresentation ? 120 : 50
            if translation > threshhold {
                debugLog("Called Down With Threshold \(translation)")
                PanelAnimationState.shared.currentPanelState = .home
                UIManager.shared.applyOpeningLayout()
                ScrollHandler.shared.openFull()
            }
        }
        .panGesture(direction: .up) { translation, phase in
            debugLog("Called Up")
            guard UIManager.shared.panelState == .open else { return }
            
            if WidgetHoverState.shared.isHoveringOverEventWidget {
                debugLog("Ignoring scroll — hovering EventWidget")
                return
            }
            if animationState.currentPanelState == .file_tray || animationState.currentPanelState == .utils || animationState.currentPanelState == .popInPresentation { return }

            if translation > 50 {
                UIManager.shared.applyOpeningLayout()
                ScrollHandler.shared.closeFull()
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // Handle files from Finder
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                        
                        debugLog("✅ Dropped file path: \(url.path)")
                        
                        // Check if this is a duplicate file
                        if !DroppedFileTracker.shared.isNewFile(url: url) {
                            debugLog("❌ Duplicate file detected - ignoring")
                            return
                        }
                        
                        let renamedFile = "DroppedFile-\(UUID().uuidString)\(url.pathExtension.isEmpty ? "" : ".\(url.pathExtension)")"
                        let destURL = settings.fileTrayDefaultFolder.appendingPathComponent(renamedFile)
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: destURL)
                            debugLog("📁 Copied to: \(destURL.path)")
                            
                            // Register the file in our tracker
                            DroppedFileTracker.shared.registerFile(url: destURL)
                            
                            DispatchQueue.main.async {
                                PanelAnimationState.shared.droppedFiles.append(destURL)
                            }
                        } catch {
                            debugLog("❌ Failed to copy file: \(error)")
                        }
                    }
                }
            }
            
            // Handle screenshots or in-memory images
            else if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { object, error in
                    if let image = object as? NSImage,
                       let tiffData = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                        
                        debugLog("📸 Received image from drag")
                        
                        // Check if this is a duplicate image
                        if !DroppedFileTracker.shared.isNewData(data: pngData) {
                            debugLog("❌ Duplicate image detected - ignoring")
                            return
                        }
                        
                        let tempURL = settings.fileTrayDefaultFolder.appendingPathComponent("DroppedImage-\(UUID().uuidString).png")
                        
                        do {
                            try pngData.write(to: tempURL)
                            debugLog("✅ Saved image to: \(tempURL.path)")
                            
                            // Register the file in our tracker
                            DroppedFileTracker.shared.registerFile(url: tempURL)
                            
                            DispatchQueue.main.async {
                                PanelAnimationState.shared.droppedFiles.append(tempURL)
                            }
                        } catch {
                            debugLog("❌ Failed to save image: \(error)")
                        }
                    }
                }
            }
        }
        
        return true
    }}
