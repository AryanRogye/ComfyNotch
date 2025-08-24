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

@MainActor
class NotchStateManager: ObservableObject {
    
    static let shared = NotchStateManager()
    
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var currentPanelWidth: CGFloat = UIManager.shared.startPanelWidth
    
    @Published var currentPanelState: NotchViewState = .home
    @Published var currentPopInPresentationState: PopInPresenterType = .nowPlaying
    @Published var utilsSelectedTab : UtilsTab = .clipboard
    
    @Published var isLoadingPopInPresenter = false
    
    /// Used to show red box around the proximity
    @Published var shouldVisualizeProximity : Bool = false
    
    let hoverHandler = HoverHandler()
    
    init() {
        hoverHandler.bindHoveringOverLeft(for: self)
    }
}

@MainActor
class ComfyNotchViewModel: ObservableObject {
    
    let uiManager = UIManager.shared
    let scrollManager = ScrollManager.shared
    let notchStateManager = NotchStateManager.shared
    var fileDropManager :FileDropManager? = nil
    
    
    @Published var isHoveringOverNotch: Bool = false
    
    public func assignFileDropManager(fileDropManager: FileDropManager) {
        self.fileDropManager = fileDropManager
    }
    
    public func handleHover(_ hovering: Bool) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
            self.isHoveringOverNotch = hovering
            && uiManager.panelState == .closed
            && !AudioManager.shared.nowPlayingInfo.isPlaying
        }
    }
    
    public func handleScrollDown(translation: CGFloat, phase: NSEvent.Phase) {
        guard uiManager.panelState == .closed else { return }
        let threshold : CGFloat = notchStateManager.currentPanelState == .popInPresentation ? 420 : 250
        
        if translation > threshold {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1)) {
                self.isHoveringOverNotch = false
            }
            uiManager.applyOpeningLayout()
            scrollManager.openFull()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.uiManager.applyExpandedWidgetLayout()
            }
        }
    }
    
    public func handleScrollUp(translation: CGFloat, phase: NSEvent.Phase) {
        guard uiManager.panelState == .open else { return }
        let threshold: CGFloat = 50
        switch phase {
        case .ended:
            if translation > threshold {
                self.isHoveringOverNotch = false
                uiManager.applyOpeningLayout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                    guard let self = self else { return }
                    self.scrollManager.closeFull()
                }
            }
        default: break
        }
    }
    
    public func handleDrop() {
        guard let fileDropManager = fileDropManager else { return }
        fileDropManager.shouldAutoShowTray = true
        /// Set the page of the notch to be the home
        notchStateManager.currentPanelState = .home
        /// Fade Out the Contents
        uiManager.applyOpeningLayout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            /// Open
            ScrollManager.shared.openFull()
        }
        
        /// Change View to File Tray
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.notchStateManager.currentPanelState = .file_tray
        }
        /// This will help with snapping on the filetray view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            fileDropManager.shouldAutoShowTray = false
        }
    }
}

struct ComfyNotchView: View {
    
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    
    @StateObject private var fileDropManager = FileDropManager()
    @StateObject private var qrCodeManager = QRCodeManager()
    @StateObject private var viewModel = ComfyNotchViewModel()

    @ObservedObject private var notchStateManager = NotchStateManager.shared
    @ObservedObject private var uiManager      = UIManager.shared
    @ObservedObject private var settings       = SettingsModel.shared
    @ObservedObject var scrollManager = ScrollManager.shared

    @State private var didTriggerLeftSwipe = false
    @State private var didTriggerRightSwipe = false
    
    @State private var notchClickManager : NotchClickManager? = nil
    @State private var hasAppearedOnce: Bool = false
    
    init() {}
    
    let restrictedStates: Set<NotchViewState> = [.file_tray, .utils, .popInPresentation, .messages]
    
    var body: some View {
        VStack {
            if hasAppearedOnce {
                ZStack(alignment: .top) {
                    
                    HoverView(isHovering: $isHovering)
                        .frame(width: settings.proximityWidth, height: settings.proximityHeight)
                    
                    // FOREGROUND LAYER – Actual UI
                    HStack(alignment: .top) {
                        Spacer()
                        notch
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            qrCodeManager.assignFileDropManager(fileDropManager)
            viewModel.assignFileDropManager(fileDropManager: fileDropManager)
            notchClickManager = NotchClickManager(settingsCoordinator: settingsCoordinator)
        }
        .onAppear {
            hasAppearedOnce = true
        }
        .animation(.easeInOut, value: hasAppearedOnce)
    }
    
    // MARK: - Swiping Left and Right
    //            .panGesture(direction: .right) { translation, phase in
    //                guard uiManager.panelState == .closed else { return }
    //
    //                let threshold: CGFloat = 200.0
    //
    //                switch phase {
    //                case .changed:
    //                    if translation > threshold/2 {
    //                        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    //                    }
    //                    if translation > threshold, !didTriggerRightSwipe {
    //                        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    //                        AudioManager.shared.playNextTrack()
    //                        didTriggerRightSwipe = true
    //                    }
    //                case .ended, .cancelled:
    //                    didTriggerRightSwipe = false
    //                default:
    //                    break
    //                }
    //            }
    //            .panGesture(direction: .left) { translation, phase in
    //                guard uiManager.panelState == .closed else { return }
    //
    //                let threshold: CGFloat = 200.0
    //
    //                switch phase {
    //                case .changed:
    //                    if translation > threshold/2 {
    //                        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    //                    }
    //                    if translation > threshold, !didTriggerLeftSwipe {
    //                        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    //                        AudioManager.shared.playPreviousTrack()
    //                        didTriggerLeftSwipe = true
    //                    }
    //                case .ended, .cancelled:
    //                    didTriggerLeftSwipe = false
    //                default:
    //                    break
    //                }
    //            }
    //
    //        // MARK: - Scrolling Logic
    //            .panGesture(direction: .down) { translation, phase in
    //                guard uiManager.panelState == .closed else { return }
    //
    //                let threshold : CGFloat = notchStateManager.currentPanelState == .popInPresentation ? 420 : 250
    //
    //                if translation > threshold {
    //                    notchStateManager.currentPanelState = .home
    //                    uiManager.applyOpeningLayout()
    //                    DispatchQueue.main.async {
    //                        CATransaction.flush()
    //                        DispatchQueue.main.async {
    //                            ScrollHandler.shared.openFull()
    //                        }
    //                    }
    //                }
    //            }
    //            .panGesture(direction: .up) { translation, phase in
    //                guard uiManager.panelState == .open else { return }
    //                // Early return for states that shouldn't handle pan up
    //
    //                var threshold : CGFloat = settings.notchScrollThreshold
    //
    //                if restrictedStates.contains(notchStateManager.currentPanelState) {
    //                    threshold = 3000
    //                }
    //
    //                if WidgetHoverState.shared.isHovering {
    //                    threshold = 3000
    //                }
    //                if WidgetHoverState.shared.isHoveringOverEvents {
    //                    threshold = settings.eventWidgetScrollUpThreshold
    //                }
    //
    //                switch phase {
    //                default:
    //                    if translation > threshold {
    //                        if settings.enableMetalAnimation {
    //                            MetalAnimationState.shared.stopAnimatingBlur()
    //                        }
    //                        uiManager.applyOpeningLayout()
    //                        /// This will make sure that the applyOpeningLayout will
    //                        /// actually do something because the CATransaction
    //                        /// Force commits of pending layout changes
    //                        DispatchQueue.main.async {
    //                            CATransaction.flush()
    //                            ScrollHandler.shared.closeFull()
    //                        }
    //                    }
    //                }
    //            }
    
    // MARK: - NOTCH
    private var notch: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // MARK: - Top Widgets
                TopNotchView()
                    .environmentObject(widgetStore)
                
                // MARK: - Bottom Widgets
                if uiManager.panelState == .open || notchStateManager.currentPanelState == .popInPresentation {
                    expandedView
                        .padding(.horizontal, 4)
                }
            }
        }
        // MARK: - WIDTH AND HEIGHT
        .frame(width: scrollManager.notchSize.width, height: scrollManager.notchSize.height, alignment: .top)
        /*
         * NOTE: This is used to make sure that if the PopInPresenter is showing when we open
         * the notch, it will switch to the home state.
         * You can test for this:
         *         1. commenting the bottom section
         *         2. settings hoverTargetMode to .album
         *         3. Make sure music is playing
         *         4. Hover over the compactAlbumWidget
         *         5. Click or Scroll down on the notch
         * You will see that the popInPresenter will show, that is
         * the reason we need the bottom section
         */
        .onChange(of: uiManager.panelState) { _, newState in
            if newState == .open {
                if notchStateManager.currentPanelState == .popInPresentation {
                    notchStateManager.currentPanelState = .home
                }
            }
        }
        // MARK: - Metal Or Black Background
        /*
         * NOTE: Background For Metal Animation can be found in Animation Tab
         * This is for the metal background to normalize to its set color on the panel change
         */
        .onChange(of: uiManager.panelState) { _, newState in
            handleBlurringBackground(newState)
        }
        .background(
            settings.enableMetalAnimation
            ? AnyView(MetalBackground().ignoresSafeArea())
            : AnyView(Color.black.ignoresSafeArea())
        )
        
        // MARK: - Notch Shape
        .mask(
            ComfyNotchShape(
                topRadius: scrollManager.notchRadius.topRadius,
                bottomRadius: scrollManager.notchRadius.bottomRadius
            )
        )
        .scaleEffect(
            x: viewModel.isHoveringOverNotch ? 1.08 : 1.0,
            y: viewModel.isHoveringOverNotch ? 1.05 : 1.0,
            anchor: .top
        )
        .shadow(radius: viewModel.isHoveringOverNotch ? 8 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1), value: viewModel.isHoveringOverNotch)
        
        // MARK: - Hover Off Detection
        .onChange(of: isHovering) { _, isHovering in
            /// Add Back Settings Window as well
            if uiManager.panelState == .open && !isHovering {
                viewModel.handleScrollUp(translation: 51, phase: .ended)
            }
        }
        
        // MARK: - Scrolling Logic
        .panGesture(direction: .down) { translation, phase in
            viewModel.handleScrollDown(translation: translation, phase: phase)
        }
        .panGesture(direction: .up) { translation, phase in
            viewModel.handleScrollUp(translation: translation, phase: phase)
        }
        // MARK: - Drop Logic
        .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $fileDropManager.isDroppingFiles) { providers in
            fileDropManager.handleDrop(providers: providers)
        }
        /// This is to show the file tray area when dropped
        .onChange(of: fileDropManager.isDroppingFiles) { _, hovering in
            if hovering && uiManager.panelState == .closed {
                viewModel.handleDrop()
            }
        }
        .onHover {
            viewModel.handleHover($0)
        }
        .onTapGesture {
            if uiManager.panelState == .closed {
                viewModel.handleScrollDown(translation: 251, phase: .ended)
            }
        }
        .contextMenu {
            ForEach(TouchAction.allCases, id: \.self) { action in
                Button(action.displayName) {
                    self.notchClickManager?.handleFingerAction(for: action)
                }
            }
        }
    }
    
    @State private var isHovering: Bool = false
    
    /// The expanded view was switched from a switch statement to
    /// if conditionals because I saw CPU lower a TON with it
    @ViewBuilder
    private var expandedView: some View {
        if notchStateManager.currentPanelState == .home {
            HomeNotchView()
                .environmentObject(bigWidgetStore)
                .frame(width: scrollManager.notchSize.width, height: scrollManager.notchSize.height - scrollManager.getNotchHeight())
                .padding(.horizontal, 8)
        }
        
        if notchStateManager.currentPanelState == .file_tray {
            FileTrayView()
                .environmentObject(fileDropManager)
                .environmentObject(qrCodeManager)
                .padding(.horizontal, 8)
        }
        
        if notchStateManager.currentPanelState == .messages {
            MessagesView()
        }
        
        if notchStateManager.currentPanelState == .utils {
            UtilsView()
        }
        
        if notchStateManager.currentPanelState == .popInPresentation {
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
