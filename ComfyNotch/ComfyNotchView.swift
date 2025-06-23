import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

enum NotchViewState {
    case home
    case file_tray
    case messages
    case utils
    case popInPresentation
}

class PanelAnimationState: ObservableObject {
    
    static let shared = PanelAnimationState()
    
    @Published var isExpanded: Bool = false
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var currentPanelWidth: CGFloat = UIManager.shared.startPanelWidth
    @Published var isDroppingFiles = false
    
    @Published var currentPanelState: NotchViewState = .home
    
    @Published var currentPopInPresentationState: PopInPresenterType = .nowPlaying
    @Published var isLoadingPopInPresenter = false
    
    /// This is used for iffffff the notch was opened by dragging
    /// we wanna show a cool animation for it getting activated so the user
    /// doesnt think its blue all the time lol
    @Published var fileTriggeredTray: Bool = false
    
    @Published var utilsSelectedTab : UtilsTab = .clipboard
    
    let hoverHandler = HoverHandler()
    
    init() {
        hoverHandler.bindHoveringOverLeft(for: self)
    }
}

struct ComfyNotchView: View {
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    
    @StateObject private var fileDropManager = FileDropManager()
    
    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings = SettingsModel.shared
    
    @Binding private var isDroppingFiles: Bool
    
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
        
        _isDroppingFiles = isDroppingFilesBinding
    }
    
    var body: some View {
        ZStack {
            //            MetalBlobView()
            //                .ignoresSafeArea()
            Color.clear
                .contentShape(Rectangle())
                .padding(-100) // expands hit area
                .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $isDroppingFiles) { providers in
                    fileDropManager.handleDrop(providers: providers)
                }
            
            VStack(alignment: .leading,spacing: 0) {
                /// Compact Widgets
                TopNotchView()
                    .environmentObject(widgetStore)
                
                /// see QuickAccessWidget.swift file to see how it works
                switch animationState.currentPanelState {
                case .home:         HomeNotchView().environmentObject(bigWidgetStore)
                case .file_tray:    FileTrayView().environmentObject(fileDropManager)
                case .messages:     MessagesView()
                case .utils:        UtilsView()
                case .popInPresentation: PopInPresenter()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .background(
                settings.enableMetalAnimation
                ? AnyView(MetalBackground().ignoresSafeArea())
                : AnyView(Color.black.ignoresSafeArea())
            )
            /// This is for the metal background to normalize to its set color
            .onChange(of: UIManager.shared.panelState) { _, newState in
                MetalAnimationState.shared.animateBlurProgress(
                    to: newState == .open ? 1.0 : 0.0,
                    duration: newState == .open ? 2 : 0.5
                )
            }
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
                /// Set the page of the notch to be the home
                animationState.currentPanelState = .home
                /// Fade Out the Contents
                UIManager.shared.applyOpeningLayout()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    DispatchQueue.main.async {
                        CATransaction.flush()
                        DispatchQueue.main.async {
                            /// Open
                            ScrollHandler.shared.openFull()
                        }
                    }
                }
                
                /// Change View to File Tray
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    animationState.currentPanelState = .file_tray
                    animationState.isExpanded = true
                }
                /// This will help with snapping on the filetray view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
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
                DispatchQueue.main.async {
                    CATransaction.flush()
                    DispatchQueue.main.async {
                        ScrollHandler.shared.openFull()
                    }
                }
            }
        }
        .panGesture(direction: .up) { translation, phase in
            //            debugLog("Called Up")
            guard UIManager.shared.panelState == .open else { return }
            
            if WidgetHoverState.shared.isHoveringOverEventWidget {
                debugLog("Ignoring scroll — hovering EventWidget")
                return
            }
            
            if (animationState.currentPanelState == .file_tray
                || animationState.currentPanelState == .utils
                || animationState.currentPanelState == .popInPresentation
                || animationState.currentPanelState == .messages) {
                return
            }
            
            if translation > 50 {
                UIManager.shared.applyOpeningLayout()
                /// This will make sure that the applyOpeningLayout will
                /// actually do something because the CATransaction
                /// Force commits of pending layout changes
                DispatchQueue.main.async {
                    CATransaction.flush()
                    DispatchQueue.main.async {
                        ScrollHandler.shared.closeFull()
                    }
                }
            }
        }
    }    
}
