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
    
    @Published var currentPanelState: NotchViewState = .home
    @Published var currentPopInPresentationState: PopInPresenterType = .nowPlaying
    @Published var utilsSelectedTab : UtilsTab = .clipboard
    
    @Published var isLoadingPopInPresenter = false
    
    let hoverHandler = HoverHandler()
    
    init() {
        hoverHandler.bindHoveringOverLeft(for: self)
    }
}

struct ComfyNotchView: View {
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    
    @StateObject private var fileDropManager = FileDropManager()
    @StateObject private var notchClickManager = NotchClickManager()
    
    @ObservedObject private var animationState = PanelAnimationState.shared
    @ObservedObject private var uiManager      = UIManager.shared
    @ObservedObject private var settings       = SettingsModel.shared
    
    init() {
    }
    
    // MARK: - Main Body
    var body: some View {
        notch
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        /// MODIFIERS
        
        /// This manager was added in to make sure that the popInPresentation is playing
        /// when we open it, it doesnt bug out
            .onChange(of: uiManager.panelState) { _, newState in
                if newState == .open {
                    if animationState.currentPanelState == .popInPresentation {
                        animationState.currentPanelState = .home
                    }
                }
            }
        
        /// This is to show the file tray area when dropped
            .onChange(of: fileDropManager.isDroppingFiles) { _, hovering in
                if hovering && uiManager.panelState == .closed {
                    fileDropManager.shouldAutoShowTray = true
                    /// Set the page of the notch to be the home
                    animationState.currentPanelState = .home
                    /// Fade Out the Contents
                    uiManager.applyOpeningLayout()
                    
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
                        fileDropManager.shouldAutoShowTray = false
                    }
                }
            }
            // MARK: - Scrolling Logic
            .panGesture(direction: .down) { translation, phase in
                guard uiManager.panelState == .closed else { return }
                
                let threshhold : CGFloat = animationState.currentPanelState == .popInPresentation ? 120 : 50
                if translation > threshhold {
                    // debugLog("Called Down With Threshold \(translation)")
                    animationState.currentPanelState = .home
                    uiManager.applyOpeningLayout()
                    DispatchQueue.main.async {
                        CATransaction.flush()
                        DispatchQueue.main.async {
                            ScrollHandler.shared.openFull()
                        }
                    }
                }
            }
            .panGesture(direction: .up) { translation, phase in
                guard uiManager.panelState == .open else { return }
                
                /// TODO: idk what this is look into it pls
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
                    uiManager.applyOpeningLayout()
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
            .onAppear {
                notchClickManager.setOpenWindow(openWindow)
                notchClickManager.startMonitoring()
            }
            .onDisappear {
                notchClickManager.stopMonitoring()
            }
    }
    
    // MARK: - NOTCH
    private var notch: some View {
        ZStack {
            /// Notch
            VStack(alignment: .leading,spacing: 0) {
                /// Compact Widgets
                TopNotchView()
                    .environmentObject(widgetStore)
                
                if animationState.isExpanded || animationState.currentPanelState == .popInPresentation {
                    /// see QuickAccessWidget.swift file to see how it works
//                    if settings.isFirstLaunch {
//                        Onboarding()
//                            .padding(.horizontal, 4)
//                    } else {
                        expandedView
                            .padding(.horizontal, 4)
//                    }
                        
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            /// This is for the metal background to normalize to its set color
            .onChange(of: uiManager.panelState) { _, newState in
                handleBlurringBackground(newState)
            }
            /// Notch Background
            .background(
                settings.enableMetalAnimation
                ? AnyView(MetalBackground().ignoresSafeArea())
                : AnyView(Color.black.ignoresSafeArea())
            )
            /// Notch Shape
            .mask(
                ComfyNotchShape(
                    topRadius: 8,
                    bottomRadius: 13
                )
            )
            .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $fileDropManager.isDroppingFiles) { providers in
                fileDropManager.handleDrop(providers: providers)
            }
        }
    }
    
    /// The expanded view was switched from a switch statement to
    /// if conditionals because I saw CPU lower a TON with it
    @ViewBuilder
    private var expandedView: some View {
        if animationState.currentPanelState == .home {
            HomeNotchView()
                .environmentObject(bigWidgetStore)
        }
        
        if animationState.currentPanelState == .file_tray {
            FileTrayView()
                .environmentObject(fileDropManager)
        }
        
        if animationState.currentPanelState == .messages {
            MessagesView()
        }
        
        if animationState.currentPanelState == .utils {
            UtilsView()
        }
        
        if animationState.currentPanelState == .popInPresentation {
            PopInPresenter()
        }
    }
    
    private func handleBlurringBackground(_ panelState: PanelState) {
        MetalAnimationState.shared.animateBlurProgress(
            /// if open then blur to 1, if its closed then blur to 0
            to: panelState == .open ? 1.0 : 0.0,
            /// if open then take 2 seconds to blur, if closed then take 0.5 seconds to unblur
            duration: panelState == .open ? 2 : 0.5
        )
    }
}


/// Preview in Xcode 26 works for ComfyNotch
#Preview {
    let widgetStore = CompactWidgetsStore()
    let bigWidgetStore = ExpandedWidgetsStore()
    
    let settings = SettingsButtonWidget()
    let dots = MovingDotsView()
    let quick = QuickAccessWidget()
    let com = CompactAlbumWidget()
    
    let musicPlayer = MusicPlayerWidget()
    
    widgetStore.addWidget(settings)
    widgetStore.addWidget(dots)
    widgetStore.addWidget(quick)
    widgetStore.addWidget(com)
    
    
    bigWidgetStore.addWidget(musicPlayer)
    
    PanelAnimationState.shared.currentPanelState = .file_tray
    PanelAnimationState.shared.isExpanded = true
    
    UIManager.shared.panelState = .open
    
    return ZStack {
        Color.gray.opacity(0.2) // Just to visualize the frame
        ComfyNotchView()
            .environmentObject(widgetStore)
            .environmentObject(bigWidgetStore)
    }
    .frame(width: 350, height: 180)
}
