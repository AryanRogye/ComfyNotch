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
    @Published var currentPopInPresentationState: PopInPresenterType = .nowPlaying
    @Published var isLoadingPopInPresenter = false
    /// This is used for iffffff the notch was opened by dragging
    /// we wanna show a cool animation for it getting activated so the user
    /// doesnt think its blue all the time lol
    @Published var fileTriggeredTray: Bool = false
    
    @Published var droppedFile: URL?

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
            //            MetalBlobView()
            //                    .ignoresSafeArea()
            Color.clear
                .contentShape(Rectangle())
                .padding(-100) // expands hit area
                .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $isDroppingFiles) { providers in
                    handleDrop(providers: providers)
                }
            
            RoundedCornersShape(
                topLeft: 0,
                topRight: 0,
                bottomLeft: cornerRadius,
                bottomRight: cornerRadius
            )
            .fill(Color.black, style: FillStyle(eoFill: true))
            .contentShape(Rectangle())
//            .offset(y: dragProgress * 12)
//            .scaleEffect(1 + dragProgress * 0.03)
//            .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $isDroppingFiles) { providers in
//                handleDrop(providers: providers)
//            }
            
            
            
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
        /// MODIFIERS
        /// This manager was added in to make sure that the popInPresentation is playing
        /// when we open it, it doesnt bug out
        .onChange(of: UIManager.shared.panelState) { _, newState in
            if newState == .open {
                if PanelAnimationState.shared.currentPanelState == .popInPresentation {
                    PanelAnimationState.shared.currentPanelState = .home
                }
            }
        }
        /// This is to show the file tray area when dropped
        .onChange(of: PanelAnimationState.shared.isDroppingFiles) { _, hovering in
            if hovering && UIManager.shared.panelState == .closed {
                animationState.fileTriggeredTray = true
                /// Set the page of the notch to be the file tray
                /// Open the panel
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIManager.shared.applyOpeningLayout()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    animationState.isExpanded = true
                    ScrollHandler.shared.openFull()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    animationState.currentPanelState = .file_tray
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
//                debugLog("Called Down With Threshold \(translation)")
                PanelAnimationState.shared.currentPanelState = .home
                UIManager.shared.applyOpeningLayout()
                ScrollHandler.shared.openFull()
            }
        }
        .panGesture(direction: .up) { translation, phase in
//            debugLog("Called Up")
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
        
        let fm = FileManager.default
        let sessionDir = fm.temporaryDirectory.appendingPathComponent("FileDropperSession-\(UUID().uuidString)", isDirectory: true)
        try? fm.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        
        for provider in providers {
            
            /// ---------- Finder files ----------
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) {
                    url, inPlace, _ in
                    guard let srcURL = url else { return }
                    
                    processFile(at: srcURL,
                                copyIfNeeded: !inPlace,
                                sessionDir: sessionDir)
                    
                }
                
            // ---------- Images / screenshots ----------
            } else if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                    guard let img = object as? NSImage,
                          let tiff = img.tiffRepresentation,
                          let rep  = NSBitmapImageRep(data: tiff),
                          let png  = rep.representation(using: .png, properties: [:])
                    else { return }
                    
                    let tmpURL = sessionDir.appendingPathComponent(
                        "DroppedImage-\(UUID()).png")
                    
                    Task.detached(priority: .utility) {
                        try? png.write(to: tmpURL)   // fast, one write
                        await processFile(at: tmpURL,
                                          copyIfNeeded: false,
                                          sessionDir: sessionDir)
                    }
                }
            }
            
            // ---------- Promised files ----------
            else if provider.registeredTypeIdentifiers.contains("com.apple.filepromise") {
                provider.loadDataRepresentation(forTypeIdentifier: "com.apple.filepromise") { _, error in
                    if let error = error {
                        debugLog("❌ Failed to receive file promise: \(error)")
                        return
                    }
                    debugLog("ℹ️ File promise received — but not handled in this version")
                }
            }
        }
        
        return true
    }
    
    private func processFile(at url: URL,
                             copyIfNeeded: Bool,
                             sessionDir: URL) {
        Task.detached(priority: .utility) {
            guard let (size, hash) = DroppedFileTracker.shared.quickHash(url: url),
                  DroppedFileTracker.shared.isNewFile(size: size, hash: hash) else {
                debugLog("Duplicate File Detected: \(url)")
                return
            }
            
            let settings = SettingsModel.shared
            let saveFolder = settings.fileTrayDefaultFolder
            
            try? FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
            let destURL = saveFolder.appendingPathComponent(url.lastPathComponent)
            let sourceURL = copyIfNeeded ? url : url // ← future-proof
            try? FileManager.default.copyItem(at: sourceURL, to: destURL)
            
            DroppedFileTracker.shared.registerFile(size: size,
                                                   hash: hash,
                                                   url: destURL)
            
            // 3. Tell SwiftUI
            await MainActor.run {
                PanelAnimationState.shared.droppedFile = destURL
            }
        }
    }
}
